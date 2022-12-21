/*
 * Created by Megan E. Cherry
 * Last Updated 11/17/2020
 * 
 * Macro consolidates the below time-lapse image functions:
 * 		Flatten Tiff image stacks
 * 		Contrast enhance brightfield images
 * 		Batch discoidal filter
 * 		Make substacks of flattened images
 * 		
 */

var darkPix = 1450; //old microscope dark count = 2130

macro TL_Process_Images_2_{
	
	//Ask user for processing parameters
	Dialog.create("");
	Dialog.addNumber("	# of Dark Pixels?", 1450);
	Dialog.addCheckbox("High Intensity Signal?", false);
	Dialog.addMessage("Which fluorescence channel(s) need to be processed? \nSeperate multiple values with semi-colons.");
	Dialog.addString("","568");
	Dialog.addMessage("Which processes should be carried out on images? ");
	//Dialog.addCheckbox("Merge Pre- and Post- UV Images?", false);
	Dialog.addCheckbox("Correct BF Channel?", false);
	Dialog.addCheckbox("Flatten Fluorescence Channel(s)?", false);
	Dialog.addCheckbox("Apply Discoidal Filter?", false);
	Dialog.addCheckbox("Make Flattened Substacks?", false);
	Dialog.addNumber("Start: ", 0);
	Dialog.addNumber("End: ", 9);
	Dialog.show();

	darkPix = Dialog.getNumber();
	highInt = Dialog.getCheckbox();
	allChans = split(Dialog.getString(),";");
	//uvMerge = Dialog.getCheckbox();
	correctBF = Dialog.getCheckbox();
	flattenFL = Dialog.getCheckbox();
	filterFL = Dialog.getCheckbox();
	substack = Dialog.getCheckbox();
	start = Dialog.getNumber();
	end = Dialog.getNumber();

	//Ask user for location of the images to process and assign rootFolder as the parent of that folder
	inputFolder= getDirectory("Find the location of raw images");
	rootFolder = File.getParent(inputFolder) + "\\"

	//Define various method save folders
	//mergedFolder = rootFolder + "UV_MERGED\\";
	filterFolder = rootFolder + "DISCOIDAL FILTERED\\";
	bfFolder = rootFolder + "CORRECTED_BF\\";
	flatFolder = rootFolder + "FLATTENED_FL\\";
	subFolder = rootFolder + "SUBSTACK_" + start + "_" + end + "\\";

	//if user wants to create flattened substacks, check to see if flattened images exist. If they don't, set flattenFL to true
	if(substack){
		if(!File.exists(flatFolder))
			flattenFL = true;
	}

	/*if(uvMerge == true){
		
		File.makeDirectory(mergedFolder);
		pre = getDirectory("Pre-UV Image Folder");
		post = getDirectory("Post-UV Image Folder");

		MergeUV(pre, post, mergedFolder);
		inputFolder = mergedFolder;
	}*/

	//Contrast Enhancement of brightfield images
	//First using keywords, identify all BF images in inputFolder, then use a beam profile to enhance cell/ background contrast
	if(correctBF){
		imageList = getChannelImages(inputFolder, "BF");
		if(imageList.length <1)
			imageList = getChannelImages(inputFolder, "BF");
		if(imageList.length < 1)
			imageList = getChannelImages(inputFolder, "BF2");

		File.makeDirectory(bfFolder);
		beamProfile = makeProfile(imageList, inputFolder, true, false, "BF", bfFolder);
		flattenImages(imageList, inputFolder, beamProfile, true, bfFolder);
	}
	//Image flattening and discoidal filtering for all fluorescent channel images
	if(flattenFL || filterFL){
		for(i=0; i<allChans.length; i++){
			channel = allChans[i];
			imageList = getChannelImages(inputFolder, channel);
			beamProfile = "";
			
			if(flattenFL){
				if(!File.exists(flatFolder))
					File.makeDirectory(flatFolder);
				if(highInt)
					beamProfile = makeProfile(imageList, inputFolder, false, true, channel, flatFolder);
				else
					beamProfile = makeProfile(imageList, inputFolder, false, false, channel, flatFolder);
			}
			
			for(j=0; j<imageList.length; j++){
				image = imageList[j];
				open(inputFolder + image);
				imageID = getImageID();

				if(filterFL){
					run("Duplicate...", "duplicate");
					if(!File.exists(filterFolder))
						File.makeDirectory(filterFolder);
						
					run("Discoidal Averaging Filter", "inner_radius=1 outer_radius=4 stack");
					run("Enhance Contrast", "saturated=0.35");
					saveAs("tiff", filterFolder + image);
				}
				
				if(flattenFL){
					selectImage(imageID);
					flattenImage(image, beamProfile, false, flatFolder);

					if(substack){
						if(end < nSlices){
							if(!File.exists(subFolder))
								File.makeDirectory(subFolder);
							makeSubstack(start, end, image, subFolder);
						}		
					}
				}
				close("*");
			}
		}

		substack = false;
		run("Clear Results");
	}	

	if(substack){
		for(i=0; i<allChans.length; i++){
			channel = allChans[i];
			imageList = getChannelImages(inputFolder, channel);

			for(j=0; j<imageList.length; j++){
				image = imageList[j];
				open(flatFolder + image);
				
				if(end > nSlices)
					return;
				
				if(!File.exists(subFolder)
					File.makeDirectory(subFolder);
					
				makeSubstack(start, end, image, subFolder);
				close("*");
			}
		}
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

function makeSubstack(start, end, image, outputFolder){
	substack = "" + start + "-" + end;
	run("Duplicate...", "duplicate range=" + substack);
	saveAs("tiff", outputFolder + image);

	return;
}

function makeProfile(imageArray, inputFolder, bf_bool, highInt_bool, channel, outputFolder){
	for(h=0; h<imageArray.length; h++){
		image = imageArray[h];
		open(inputFolder + image);
	}

	run("Concatenate...", "all_open title=[Concatenated Stacks]"); //concatenate the stacks
	run("Subtract...", "value=" + darkPix + " stack");	//subtract background intensity
	run("Z Project...", "projection=[Average Intensity]");	//Flatten stack
	run("32-bit");	//make into a 32-bit image

	if(!bf_bool){
		run("Gaussian Blur...", "sigma=50 stack");	//Apply Gaussian Blur Filter
		if(highInt_bool)
			run("Median...",  "radius=100 stack");
	}
	
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

function makeMask(image, outputFolder){
	
	run("Gaussian Blur...", "sigma=3");
	setAutoThreshold("Triangle dark");
	run("Convert to Mask");

	saveAs("tiff", outputFolder + image);

	return;
}
