var darkPix = 2130;

macro RA_Process_Images_2_{

	//Ask user for location of the rootfolder and instantiate the inputFolder accordingly
	inputFolder= getDirectory("Find the location of raw images");
	rootFolder = File.getParent(inputFolder) + "\\"

	//Define various method save folders
	mergedFolder = rootFolder + "UV_MERGED\\";
	bfFolder = rootFolder + "CORRECTED_BF\\";
	flatFolder = rootFolder + "FLATTENED_FL\\";
	filterFolder = rootFolder + "DISCOIDAL FILTERED\\";

	//Ask user for processing parameters
	Dialog.create("");
	Dialog.addNumber("# of Dark Pixels: ", 200);
	Dialog.addMessage("What fluorescence channel(s) need to be processed?\n Seperate multiple channels with a semi-colon.");
	Dialog.addString("  ","514;568");
	
	Dialog.addMessage("Which processes should be carried out on images?");
	Dialog.addCheckbox("Merge Pre- and Post- UV Images?", false);
	Dialog.addCheckbox("Correct BF Channel?", false);
	Dialog.addCheckbox("Flatten Fluorescence Channel(s)?", false);

	Dialog.addCheckbox("Apply Discoidal Filter?", false);
	Dialog.addCheckbox("Make Average Projections?", false);
	Dialog.addNumber("Start: ", 1);
	Dialog.addNumber("End: ", 150);
	Dialog.addCheckbox("Make Substacks?", false);
	Dialog.addNumber("Start: ", 1);
	Dialog.addNumber("End: ", 150);
	Dialog.show();

	darkPix = Dialog.getNumber();
	allChans = split(Dialog.getString(),";");
	
	uvMerge = Dialog.getCheckbox();
	correctBF = Dialog.getCheckbox();
	flattenFL = Dialog.getCheckbox();
	filterFL = Dialog.getCheckbox();
	avgProj = Dialog.getCheckbox();
	startP = Dialog.getNumber();
	endP = Dialog.getNumber();
	substack = Dialog.getCheckbox();
	start = Dialog.getNumber();
	end = Dialog.getNumber();

	avgFolder = rootFolder + "AVG_PROJECTIONS_"+ startP + "_" + endP + "\\";
	subFolder = rootFolder + "SUBSTACK_" + start + "_" + end + "\\";

	if(uvMerge){
		
		File.makeDirectory(mergedFolder);
		pre = getDirectory("Pre-UV Image Folder");
		post = getDirectory("Post-UV Image Folder");

		MergeUV(pre, post, mergedFolder);
		inputFolder = mergedFolder;
	}

	if(correctBF){
		File.makeDirectory(bfFolder);
		imageList = getChannelImages(inputFolder, "BF");
		beamProfile = makeProfile(imageList, inputFolder, true, "BF", bfFolder);
		flattenImages(imageList, inputFolder, beamProfile, true, bfFolder);
	}

	if(flattenFL){
		for(i=0; i<allChans.length; i++){
			channel = allChans[i];
			imageList = getChannelImages(inputFolder, channel);

			if(!File.exists(flatFolder))
				File.makeDirectory(flatFolder);
				
			beamProfile = makeProfile(imageList, inputFolder, false, channel, flatFolder);

			for(j=0; j<imageList.length; j++){
				image = imageList[j];
				open(inputFolder + image);
				flattenImage(image, beamProfile, false, flatFolder);
				imageID = getImageID();

				if(avgProj){
					selectImage(imageID);
					if(!File.exists(avgFolder))
						File.makeDirectory(avgFolder);
					if(end <= nSlices)
						projectStack(startP, endP, image, avgFolder);
					else
						projectStack(startP, nSlices, image, avgFolder);
				}

				if(substack){
					selectImage(imageID);
					if(end < nSlices){
						if(!File.exists(subFolder))
							File.makeDirectory(subFolder);
						makeSubstack(start, end, image, subFolder);
					}		
				}	

				if(filterFL){
					selectImage(imageID);
					if(!File.exists(filterFolder))
						File.makeDirectory(filterFolder);
					run("Discoidal Averaging Filter", "inner_radius=1 outer_radius=4 stack");
					run("Enhance Contrast", "saturated=0.35");
					saveAs("tiff", filterFolder + image);
				}
				
				close("*");
				run("Clear Results");
			}
		}

		filterFL = false;
		avgProj = false;
		substack = false;
	}

	if(filterFL || avgProj || substack){
		for(i=0; i<allChans.length; i++){
			channel = allChans[i];
			imageList = getChannelImages(inputFolder, channel);

			for(j=0; j<imageList.length; j++){
				image = imageList[j];
				open(inputFolder + image);
				imageID = getImageID();

				if(avgProj){
					selectImage(imageID);
					if(!File.exists(avgFolder))
						File.makeDirectory(avgFolder);
					if(end <= nSlices)
						projectStack(startP, endP, image, avgFolder);
					else
						projectStack(startP, nSlices, image, avgFolder);
				}

				if(substack){
					selectImage(imageID);
					if(end < nSlices){
						if(!File.exists(subFolder))
							File.makeDirectory(subFolder);
						makeSubstack(start, end, image, subFolder);
					}		
				}

				if(filterFL){
					selectImage(imageID);
					if(!File.exists(filterFolder))
						File.makeDirectory(filterFolder);
					run("Discoidal Averaging Filter", "inner_radius=1 outer_radius=4 stack");
					run("Enhance Contrast", "saturated=0.35");
					saveAs("tiff", filterFolder + image);
				}

				close("*");
			}
		}
	}
}

function MergeUV(preFolder, postFolder, saveFolder){
	preImages = getFileList(preFolder);
	preImages = Array.sort(preImages);
	postImages = getFileList(postFolder);
	postImages = Array.sort(postImages);

	for(i=0; i<preImages.length; i++){
		
		open(preFolder + preImages[i]);
		open(postFolder + postImages[i]);
		imageName = preImages[i];

		run("Concatenate...", "  title=[" + preImages[i] + "] image1=[" + preImages[i] + "] image2=[" + postImages[i] + "] image3=[-- None --]");
		saveAs("tiff", saveFolder + imageName + ".tif");
		close("*");
	}
}

function getChannelImages(input, channel){
	allImages = getFileList(input);
	channelImages = newArray;
	for(h=0; h<allImages.length; h++){
		image_full = allImages[h];
		image_split = split(image_full, ".");
		image_split2 = split(image_full, ". ");
		image_num = image_split2[0];

		if(endsWith(image_split[0], channel) == true){
			channelImages = Array.concat(channelImages, image_full);
		}
	}

	return channelImages;
}

function makeProfile(imageArray, inputFolder, bf_bool, channel, outputFolder){

	for(h=0; h<imageArray.length; h++){
		image = imageArray[h];
		open(inputFolder + image);
		imageID = getImageID();
		
		if(!bf_bool){
			run("Z Project...", "projection=[Average Intensity]");	//Flatten stack
			selectImage(imageID);
			close();
		}
	}

	run("Concatenate...", "all_open title=[Concatenated Stacks]"); //concatenate the stacks
	run("Subtract...", "value=" + darkPix + " stack");	//subtract background intensity
	run("Z Project...", "projection=[Average Intensity]");	//Flatten stack
	run("32-bit");	//make into a 32-bit image

	if(!bf_bool)
		run("Gaussian Blur...", "sigma=50 stack");	//Apply Gaussian Blur Filter
	
	//Normalize and save
	run("Set Measurements...", "mean standard min median stack display redirect=None decimal=3");
	run("Measure");
	max = getResult("Max");
	run("Divide...", "value=" + max + " stack");
	profileImagePath = outputFolder + channel + "_profile.tif";
	saveAs("tiff", profileImagePath);

	//close all windows
	run("Close");
	close("*");

	return profileImagePath;
}

function flattenImage(imageName, beamPath, bf_bool, outputFolder){
	
	run("Subtract...", "value=" + darkPix + " stack"); //subtract background intensity
	
	open(beamPath);
	beamTitle = getTitle();
	imageCalculator("Divide create 32-bit stack", image, beamTitle); //divide image by beam profile
	close("\\Others");
	
	//For each frame, get the median intensity and subtract that
	for (j=1; j<= nSlices; j++){
		setSlice(j);
		run("Measure");
		median = getResult("Median");
		run("Subtract...", "value=" + median + " slice");
		setMinAndMax(0,65535-darkPix);
	}

	if(bf_bool){
		run("Subtract Background...", "rolling=15 light stack");
		run("8-bit");
	}
	
	else
		run("16-bit");

	run("Enhance Contrast", "saturated=0.35");
	saveAs("tiff", outputFolder + image);
	return;
}

function flattenImages(imageArray, inputFolder, beamPath, bf_bool, outputFolder){

	for(k=0; k<imageArray.length; k++){
		image = imageArray[k];
		open(inputFolder + image);
		flattenImage(image, beamPath, bf_bool, outputFolder);
		run("Close");
		close("*");
	}

	return;
}

function makeSubstack(start, end, image, outputFolder){
	substack = "" + start + "-" + end;
	run("Duplicate...", "duplicate range=" + substack);
	saveAs("tiff", outputFolder + image);

	return;
}

function projectStack(start, end, image, outputFolder){
	run("Z Project...", "start=" + start + " stop=" + end + " projection=[Average Intensity]");
	saveAs("tiff", outputFolder + image);
		
	return;
}
