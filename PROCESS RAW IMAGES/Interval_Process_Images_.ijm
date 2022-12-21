/*
 * Created October 10, 2019 by Megan Cherry
 * 
 * Edited Nov. 13th, 2019 - Ask for substack dimensions at beginning of program, add ability to make masks
 * 
 */

var darkPix = 200;
var flatFolder = "";
var start = 0;
var end = 50;

macro Interval_Process_Images_2{

	//Ask user for location of the rootfolder and instantiate the inputFolder accordingly
	inputFolder= getDirectory("Find the location of raw images");
	rootFolder = File.getParent(inputFolder) + "\\";

	Dialog.create("");
	Dialog.addNumber("	# of Dark Pixels?", 200);
	Dialog.addMessage("Which fluorescence channel(s) need to be processed? \nSeperate multiple values with semi-colons.");
	Dialog.addString("","514");

	Dialog.addMessage("Which processes should be carried out on images? ");
	Dialog.addCheckbox("Correct BF Channel?", false);
	Dialog.addCheckbox("Flatten Fluorescence Channel(s)?", true);
	Dialog.addCheckbox("Create Masks?", true);
	Dialog.addCheckbox("Generate ROIs?", true);
	Dialog.addCheckbox("Make Substacks?", true);
	Dialog.addNumber("	start: ", 0);
	Dialog.addNumber("	end: ", 50);
	Dialog.show();

	darkPix = Dialog.getNumber();
	allChans = split(Dialog.getString(),";");

	correctBF = Dialog.getCheckbox();
	flattenFL = Dialog.getCheckbox();
	masks = Dialog.getCheckbox();
	rois = Dialog.getCheckbox();
	subStack = Dialog.getCheckbox();
	start = Dialog.getNumber();
	end = Dialog.getNumber();

	bfFolder = rootFolder + "CORRECTED_BF\\";
	flatFolder = rootFolder + "FLATTENED_FL\\";
	subFolder = rootFolder + "SUBSTACKS\\";
	maskFolder = rootFolder + "MASKS\\";
	roiFolder = rootFolder + "AREA_ROIS\\";
	
	if(rois){
		if(! File.exists(maskFolder))
			masks = true;
	}
	
	if(correctBF){
		
		File.makeDirectory(bfFolder);
		
		imageList = getChannelImages(inputFolder, "BF");
		beamProfile = makeProfile(imageList, inputFolder, true, "BF", bfFolder);
		flattenImages(imageList, inputFolder, beamProfile, true, bfFolder);
	}
	
	if(flattenFL){
		
		File.makeDirectory(flatFolder);

		for(i=0; i<allChans.length; i++){
			channel = allChans[i];
			imageList = getChannelImages(inputFolder, channel);
			beamProfile = makeProfile(imageList, inputFolder, false, channel, flatFolder);  //create beam profile using avg projs
			flattenImages(imageList, inputFolder, beamProfile, false, flatFolder);  //flatten raw images
		}

		inputFolder = flatFolder;
	}

	if(subStack || masks){

		if(subStack)
			File.makeDirectory(subFolder);
		if(masks)
			File.makeDirectory(maskFolder);
		if(rois)
			File.makeDirectory(roiFolder);

		for(i=0; i<allChans.length; i++){
			channel = allChans[i];
			imageList = getChannelImages(inputFolder, channel);
			//makeSubstack(start, end, imageList, inputFolder, subFolder);

			for(j=0; j<imageList.length; j++){
				image = imageList[j];
				open(inputFolder + image);
				window = getTitle();

				if(subStack)
					makeSubstack(start, end, image, subFolder);
				if(masks){
					selectWindow(window);
					makeMask(image, maskFolder);

					if(rois){
						roiManager("reset");
						run("Analyze Particles...", "size=3-Infinity add");
						roiManager("save", roiFolder + File.nameWithoutExtension + ".zip");
					}
					
					close("*");
				}
			}
		}
		rois = false;
	}

	if(rois){
		File.makeDirectory(roiFolder);
		
		allFiles = getFileList(maskFolder);
		for(i=0; i<allFiles.length; i++){
			file = allFiles[i];
			open(maskFolder + file);
			roiManager("reset");
			run("Analyze Particles...", "size=3-Infinity add");
		
			roiManager("save", roiFolder + File.nameWithoutExtension + ".zip");
			close("*");
		}

		roiManager("reset");
	}
}



//###############################################################################################################
function getPeakSettings(){
	Dialog.create("");
	Dialog.addMessage("Substack Properties");
	Dialog.addNumber("First Frame: ", 51);
	Dialog.addNumber("Last Frame: ", 150); 
	Dialog.addMessage("Peak Picking Settings");
	Dialog.addNumber("Inner Radius: ", 1);
	Dialog.addNumber("Outer Radius: ", 3);
	Dialog.addNumber("Relative Threshold: ", 7);
	Dialog.addNumber("Min Radius: ", 4);
	Dialog.addMessage("Particle Tracker Settings");
	Dialog.addNumber("Max Pixel Drift: ", 3);
	Dialog.show();

	f1 = Dialog.getNumber();
	flast = Dialog.getNumber();
	inner = Dialog.getNumber();
	outer = Dialog.getNumber();
	thr = Dialog.getNumber();
	rad = Dialog.getNumber();
	drift = Dialog.getNumber();

	result = newArray(f1, flast, inner, outer, thr, rad, drift);
	return result;
	
}

//takes input directory and array of taus
function sortFolder(inputFolder, tauList){
	
	allFiles = getFileList(inputFolder);	//get list of files in folder
	
	//for each tau tl, create a folder and move the appropriate images to that folder
	for(i=0; i<tauList.length; i++){		
		tau = tauList[i];
		tauFolder = inputFolder + "" + tau + "\\";
		File.makeDirectory(tauFolder);

		for(j=0; j<allFiles.length; j++){
			file = allFiles[j];
			s_file = split(file, " ");
			num = parseInt(s_file[0]);

			if((num-1) %tauList.length == i)
				File.rename(inputFolder + file, tauFolder + file);	
		}
	}
}

//takes input directory and an int
function sortFolder2(inputFolder, tauNum){

	allFiles = getFileList(inputFolder);

	for(i=0; i<tauNum; i++){
		index = i + 1;
		tauFolder = inputFolder + "" + index + "\\";
		File.makeDirectory(tauFolder);

		for(j=0; j<allFiles.length; j++){
			file = allFiles[j];
			s_file = split(file, " ");
			num = parseInt(s_file[0]);

			if((num-1) % tauNum == i)
				File.rename(inputFolder + file, tauFolder + file);
		}
	}
}

function makeMask(image, outputFolder){
	run("Duplicate...", "use");
	run("Gaussian Blur...", "sigma=3");
	setAutoThreshold("Triangle dark");
	run("Convert to Mask");

	saveAs("tiff", outputFolder + image);

	return;
}

function makeSubstack(start, end, image, outputFolder){
	substack = "" + start + "-" + end;
	run("Duplicate...", "duplicate range=" + substack);
	saveAs("tiff", outputFolder + image);
	close();

	return;
}
/*
function makeSubstack(start, end, imageArray, inputFolder, outputFolder){
	substack = "" + start + "-" + end;
	for(k=0; k<imageArray.length; k++){
		image = imageArray[k];
		open(inputFolder + image);
		run("Duplicate...", "duplicate range=" + substack);
		saveAs("tiff", outputFolder + image);
		close("*");
	}	

	return;
}
*/
function projectStacks(imageArray, inputFolder, outputFolder){
	for(k=0; k<imageArray.length; k++){
		image = imageArray[k];
		open(inputFolder + image);
		run("Z Project...", "projection=[Average Intensity]");	//Flatten stack
		saveAs("tiff", outputFolder + image);
		close("*");
	}
	return;
}

function flattenImages(imageArray, inputFolder, beamPath, bf_bool, outputFolder){

	for(k=0; k<imageArray.length; k++){
		image = imageArray[k];
		open(inputFolder + image);
		run("Subtract...", "value=" + darkPix + " stack"); //subtract camera dark count
		
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
		else{
			run("16-bit");
			
		}

		run("Enhance Contrast", "saturated=0.35");
		saveAs("tiff", outputFolder + image);
		run("Close");
		//close("*");
	}
}


function makeProfile(imageArray, inputFolder, bf_bool, channel, outputFolder){
	for(h=0; h<imageArray.length; h++){
		image = imageArray[h];
		open(inputFolder + image);
	}

	run("Concatenate...", "all_open title=[Concatenated Stacks]"); //concatenate the stacks
	run("Subtract...", "value=" + darkPix + " stack");	//subtract camera dark count
	run("Z Project...", "projection=[Average Intensity]");	//Flatten stack
	run("32-bit");	//make into a 32-bit image
	if(!bf_bool)
		run("Gaussian Blur...", "sigma=50 stack");	//Apply Median Filter and save
	
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

function findPeaks(saveName, output, thr){
	run("Peak Fitter", "use_discoidal_averaging_filter inner_radius=1 outer_radius=3 threshold=6 threshold_value=" + thr + " minimum_distance=4 fit_radius=4 max_error_baseline=5000 max_error_height=5000 max_error_x=1 max_error_y=1 max_error_sigma_x=1 max_error_sigma_y=1 z_scale=1.25 stack");
	saveAs("Results", output + saveName);
	run("Close");
}