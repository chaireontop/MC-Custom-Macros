var cellROIFolder;
var rootFolder;
var cellFolder;
var particleROIFolder;
var particleStatFolder;
var particleFolder;
var peakFolder;
var overlapFolder;
var chanceFolder;

var chan1;
var data_type;

var imageArray = newArray;
var settings = newArray;
var thresh = newArray;
var i_range = newArray;
var frames = newArray;

//overlap global variables
var chan2;
var data_type2;
var peakFolder2;
var particleROIFolder2;


macro Particle_Analysis_Suite_{

	//instantiate directories
	cellROIFolder = getDirectory("Where are cell outlines located?");
	cellROIs = getFileList(cellROIFolder);
	cellROIs = Array.sort(cellROIs);
	rootFolder = File.getParent(cellROIFolder) + "\\";
	
	cellFolder = rootFolder + "\\CELL MEANS\\";
	particleROIFolder = rootFolder + "\\PARTICLE_ROIS\\";
	particleStatFolder = rootFolder + "\\PARTICLE_STATS\\";
	particleFolder = rootFolder + "\\PARTICLE_XLS\\";
	peakFolder = rootFolder + "\\PEAKS_XLS\\";
	overlapFolder = rootFolder + "\\OVERLAP\\";
	chanceFolder = rootFolder + "\\CHANCE\\";

	//determine what actions to do
	Dialog.create("");
	Dialog.addNumber("Primary Imaging Channel: ", 458);
	Dialog.addRadioButtonGroup("Data Type: ", newArray("Peak", "Particle", "Both"),1, 3 "Peak");
	Dialog.addMessage("What tasks would you like to do today?");
	Dialog.addCheckbox("Cell Mean Intensity ", false);
	Dialog.addCheckbox("Find Cell Features ", false);
	Dialog.addCheckbox("Get Feature Properties ", false);
	Dialog.addCheckbox("Get Feature % Cell Area ", false);
	Dialog.addCheckbox("Calculate Overlap Stats", false);
	Dialog.show();

	chan1 = Dialog.getNumber();
	data_type = Dialog.getRadioButton();
	job_getCellInt = Dialog.getCheckbox();
	job_getCellFeats = Dialog.getCheckbox();
	job_getFeatProps = Dialog.getCheckbox();
	job_getFeatPerArea = Dialog.getCheckbox();
	job_getOverlap = Dialog.getCheckbox();

	if(job_getCellInt || job_getCellFeats){
		//load images to imageArray
		waitForUser("Navigate to the image file which corresponds to the\n displayed cell ROI outline file.");
		imageArray = loadImageArray(cellROIs);

		//for every selected image...
		for(i=0; i<imageArray.length; i++){
			//load cell ROIs to roiManager and extract file savename
			roiManager("reset");
			open(cellROIFolder + cellROIs[i]);
			prefix = File.nameWithoutExtension;

			//open image
			open(imageArray[i]);
			imageTitle = getTitle();

			if(job_getCellInt){
				//measure mean cell intensities
				File.makeDirectory(cellFolder);
				saveName = prefix + "_" + chan1 + "_CELL MEANS.xls";
				getPixelInts(cellFolder + saveName);
			}
				
			if(job_getCellFeats){
				if(data_type == "Particle" || data_type == "Both"){
					//pick particles
					File.makeDirectory(particleROIFolder);
					savePath = particleROIFolder + prefix + "_" + chan1 + "_PARTICLES.zip";
					getCellFeats("Particle", imageTitle, savePath);
				
					if(job_getFeatProps){
						//measure particle stats and save 
						File.makeDirectory(particleStatFolder);
						savePath = particleStatFolder + prefix + "_" + chan1 + "_PARTICLES.xls";
						measureParticles(imageTitle, savePath);
						run("Organize Particles ", "find=[" + savePath + "]");
						open(imageArray[i]);	//re-open image
					}
				}	
				
				if(data_type == "Peak" || data_type == "Both"){
					//pick peaks
					File.makeDirectory(peakFolder);
					savePath = peakFolder + prefix + "_" + chan1 + ".xls";
					getCellFeats("Peak", imageTitle, savePath);

					if(job_getFeatProps)
						//measure and add peak intentisities to peak spreadsheet
						measurePeaks(imageTitle, savePath);
				}
			}
			
			close("*");		//close images
		}	

		selectWindow("Results");
		run("Close");
		roiManager("reset");

		job_getFeatProps = false;
	}
	
	if(job_getFeatProps){
		//load images to imageArray
		waitForUser("Navigate to the image file which corresponds to the\n displayed cell ROI outline file.");
		imageArray = loadImageArray(cellROIs);

		//get directory information from user
		if(data_type == "Peak" || data_type == "Both")
			peakFolder = getDirectory("Peak Spreadsheet Directory");		
			
		if(data_type == "Particle" || data_type == "Both");
			particleROIFolder = getDirectory("Particle ROI Directory");

		//for every selected image...
		for(i=0; i<imageArray.length; i++){
			//extract experiment prefix
			open(cellROIFolder + cellROIs[i]);
			prefix = File.nameWithoutExtension;
			roiManager("reset");
			
			//open image 
			open(imageArray[i]);
			imageTitle = getTitle();

			if(data_type == "Peak" || data_type == "Both"){
				peakFiles = getFileList(peakFolder);
				peakFiles = Array.sort(peakFiles);
				filepath = peakFolder + peakFiles[i];
				open(filepath);
				
				//measure and add peak intentisities to peak spreadsheet
				measurePeaks(imageTitle, filepath);
			}
			
			if(data_type == "Particle" || data_type == "Both"){
				File.makeDirectory(particleStatFolder);
				partFiles = getFileList(particleROIFolder);
				partFiles = Array.sort(partFiles);
				openPath = particleROIFolder + partFiles[i];
				savePath = particleStatFolder + prefix + "_" + chan1 + "_PARTICLES.xls";
				open(openPath);

				//measure particle stats and save
				measureParticles(imageTitle, savePath);
			}
		
			close("*");		//close images	
		}
		selectWindow("Results");
		run("Close");
		roiManager("reset");
		
	}
	
	if(job_getOverlap){	
		
		File.makeDirectory(overlapFolder);
		getOverlapSettings();	//initialize overlap global variables
		width = settings[0];
		height = settings[1];
		slices = settings[2];

		dataArray1 = newArray();
		dataArray2 = newArray();

		//get primary directories from user
		if(data_type == "Peak" || data_type == "Both"){
			peakFolder = getDirectory("Find folder for channel " + chan1 + " peak data");				
			dataString = peakFolder + ";Peak";
			dataArray1 = Array.concat(dataArray1, dataString);
		}
		
		if(data_type == "Particle" || data_type == "Both"){
			particleROIFolder = getDirectory("Find folder for channel " + chan1 + " particle ROIs");		
			dataString = particleROIFolder + ";Particle";
			dataArray1 = Array.concat(dataArray1, dataString);
		}

		//get secondary channel directories from user
		if(data_type2 == "Peak" || data_type2 == "Both"){
			peakFolder2 = getDirectory("Find folder for channel " + chan2 + " peak data");
			dataString = peakFolder2 + ";Peak";
			dataArray2 = Array.concat(dataArray2, dataString);
		}
		
		if(data_type2 == "Particle" || data_type2 == "Both"){
			particleROIFolder2 = getDirectory("Find folder for channel " + chan2 + " particle ROIs");
			dataString = particleROIFolder2 + ";Particle";
			dataArray2 = Array.concat(dataArray2, dataString);
		}

		peakFiles = getFileList(peakFolder);
		peakFiles = Array.sort(peakFiles);
		particleFiles = getFileList(particleROIFolder);
		particleFiles = Array.sort(particleFiles);
		peakFiles2 = getFileList(peakFolder2);
		peakFiles2 = Array.sort(peakFiles2);
		particleFiles2 = getFileList(particleROIFolder2);
		particleFiles2 = Array.sort(particleFiles2);

		if(data_type == "Both"){
		//first, determine internal overlap if primary channel has both peaks and particles 
			//make save directories
			save_peaks = "" + chan1 + " PEAKS TO " + chan1 + " PARTICLES\\";
			save_parts = "" + chan1 + " PARTICLES TO " + chan1 + " PEAKS\\";
			save_feats = "" + chan1 + " FEATURE SUMMARIES\\";
			File.makeDirectory(overlapFolder + save_peaks);
			File.makeDirectory(overlapFolder + save_parts);
			File.makeDirectory(overlapFolder + save_feats);

			for(i=0; i<peakFiles.length; i++){
				part_file = particleROIFolder + particleFiles[i];
				peak_file = peakFolder + peakFiles[i];
				
				//identify overlap of peaks to particles
				makeOverlapMask(width, height, slices, part_file, "Particle");
				prefix = findOverlap(peak_file, "Peak");
				savepath1 = overlapFolder + save_peaks + prefix + "_OVERLAP.xls";
				saveAs("Results", savepath1);
				close("*");
				
				//identify overlap of particles to peaks
				makeOverlapMask(width, height, slices, peak_file, "Peak");
				prefix = findOverlap(part_file, "Particle");
				savepath2 = overlapFolder + save_parts + prefix + "_OVERLAP.xls";
				saveAs("Results", savepath2);
				
				//clean up spreadsheets and calculate overlap 
				run("Organize Overlap ", "find=[" + savepath1 + "]");
				run("Organize Overlap ", "find=[" + savepath2 + "]");
				run("Calc Overlap ", "chan1=[" + savepath1 + "] chan2=[" + savepath2 + "]");
				run("Calc Overlap ", "chan1=[" + savepath2 + "] chan2=[" + savepath1 + "]");

				//cleanup the screen
				roiManager("reset");
				run("Clear Results");
				close("*");
				
			}
			
			//next, make a summary feature spreadsheet with all particles and non-particle-overlapping peaks
			overlapFolder_peaks = overlapFolder + save_peaks;
			overlapFolder_parts = overlapFolder + save_parts;
			saveFolder = overlapFolder + save_feats;
			summarizeFeatures(overlapFolder_peaks, overlapFolder_parts, saveFolder);

			//update peakFolder and file list
			peakFolder = saveFolder;
			peakFiles = getFileList(peakFolder);
			peakFiles = Array.sort(peakFiles);
			dataString = peakFolder + ";Peak";
			dataArray1[0] = dataString;
		}

		//repeat process if the secondary channel has both peaks and particles
		if(data_type2 == "Both"){
			//first, determine internal overlap if primary channel has both peaks and particles 
			//make save directories
			save_peaks = "" + chan2 + " PEAKS TO " + chan2 + " PARTICLES\\";
			save_parts = "" + chan2 + " PARTICLES TO " + chan2 + " PEAKS\\";
			save_feats = "" + chan2 + " FEATURE SUMMARIES\\";
			File.makeDirectory(overlapFolder + save_peaks);
			File.makeDirectory(overlapFolder + save_parts);
			File.makeDirectory(overlapFolder + save_feats);

			for(i=0; i<peakFiles.length; i++){
				//identify overlap of peaks to particles
				part_file = particleROIFolder2 + particleFiles2[i];
				makeOverlapMask(width, height, slices, part_file, "Particle");
				prefix = findOverlap(peakFolder2 + peakFiles2[i], "Peak");
				savepath1 = overlapFolder + save_peaks + prefix + "_OVERLAP.xls";
				saveAs("Results", savepath1);
				close("*");
				
				//identify overlap of particles to peaks
				peak_file = peakFolder2 + peakFiles2[i];
				makeOverlapMask(width, height, slices, peak_file, "Peak");
				prefix = findOverlap(particleROIFolder2 + particleFiles2[i], "Particle");
				savepath2 = overlapFolder + save_parts + prefix + "_OVERLAP.xls";
				saveAs("Results", savepath2);
				
				//clean up spreadsheets and calculate overlap 
				run("Organize Overlap ", "find=[" + savepath1 + "]");
				run("Organize Overlap ", "find=[" + savepath2 + "]");
				run("Calc Overlap ", "chan1=[" + savepath1 + "] chan2=[" + savepath2 + "]");
				run("Calc Overlap ", "chan1=[" + savepath2 + "] chan2=[" + savepath1 + "]");

				//cleanup the screen
				roiManager("reset");
				run("Clear Results");
				close("*");
			}
			
			//next, make a summary feature spreadsheet with all particles and non-particle-overlapping peaks
			overlapFolder_peaks = overlapFolder + save_peaks;
			overlapFolder_parts = overlapFolder + save_parts;
			saveFolder = overlapFolder + save_feats;
			summarizeFeatures(overlapFolder_peaks, overlapFolder_parts, saveFolder);

			//update peakFolder2 and file list
			peakFolder2 = saveFolder;
			peakFiles2 = getFileList(peakFolder2);
			peakFiles2 = Array.sort(peakFiles2);
			dataString = peakFolder2 + ";Peak";
			dataArray2[0] = dataString;
		}

	//Now calculate overlap between primary and secondary channels
		//first make save directories
		if(job_getFeatPerArea)
			File.makeDirectory(chanceFolder);
		
		save_primary = nameFolder(chan1, data_type, chan2, data_type2);
		save_secondary = nameFolder(chan2, data_type2, chan1, data_type);

		temp = split(dataArray1[0], ";");
		folder1 = temp[0];
		file_list1 = getFileList(folder1);
		file_list1 = Array.sort(file_list1);

		temp = split(dataArray2[0], ";");
		folder2 = temp[0];
		file_list2 = getFileList(folder2);
		file_list2 = Array.sort(file_list2);
	
		//get overlap of primary with secondary
		for(i=0; i<file_list1.length; i++){
			savepath1 = "";
			savepath2 = "";

			peak_file = "";
			part_file = "";
			peak_file2 = "";
			part_file2 = "";
		
			File.makeDirectory(overlapFolder + save_primary);
			File.makeDirectory(overlapFolder + save_secondary);
		
			//make mask of secondary channel
			run("Clear Results");
			roiManager("reset");
		
			if(data_type2 != "Both"){
				file2 = folder2 + file_list2[i];
				makeOverlapMask(width, height, slices, file2, data_type2);
			}

			else{
				peak_file2 = peakFolder2 + peakFiles2[i];
				part_file2 = particleROIFolder2 + particleFiles2[i];

				//start mask with chan 2 particles
				makeOverlapMask(width, height, slices, part_file2, "Particle");
			
				//extract non-overlapping peak positions from feature summary spreadsheet
				run("Clear Results");
				open(peak_file2);
				for(j=0; j<nResults; j++){
					type = getResultString("TYPE", j);
		
					if(type == "Particle"){
						IJ.deleteRows(j,j);
						rows = nResults;
						j--;
					}
				}

				//add these areas to the ROI mask
				peakToROI(2);
				selectWindow("ROI MASK");
				roiManager("show all");
				roiManager("fill");	
			}
		
			//calc percent area for secondary channel	
			if(job_getFeatPerArea){
				prefix = File.getName(cellROIs[i]);
				temp = split(prefix, ".");
				prefix = temp[0];
				savename = chanceFolder + prefix + "_" + chan2 + "_PERC AREA.xls";
				chanceColoc(savename, cellROIFolder + cellROIs[i]);
			}

			//find overlapping primary channel features
			run("Clear Results");
			roiManager("reset");
		
			if(data_type != "Both"){
				file1 = folder1 + file_list1[i];
				prefix = findOverlap(file1, data_type);
				savepath1 = overlapFolder + save_primary + prefix + "_OVERLAP.xls";
				saveAs("Results", savepath1);
				close("*");		//close ROI Mask
			}

			else{
				peak_file = peakFolder + peakFiles[i];
				part_file = particleROIFolder + particleFiles[i];
				run("Clear Results");
				open(peak_file);
				rows = nResults;
			
				for(j=0; j<rows; j++){
					type = getResultString("TYPE", j);
					if(type == "Particle"){
						IJ.deleteRows(j,j);
						rows = nResults;
						j--;
					}
				}

				//if there are peaks, find overlap and overwrite x,y coordinates.  Save to a temp array
				temp_file = overlapFolder + save_primary + "transformed-TEMP.xls";
				headings = newArray("Area", "X", "Y", "IntDen", "%Area", "RawIntDen", "Slice");
				peak_array = newArray;
				
				if(nResults > 0){
					saveAs("Results", temp_file);
					findOverlap(temp_file, "Peak");
				
					for(j=0; j<nResults; j++){
						temp = "" + getResult(headings[0], j);
						for(k=1; k<headings.length; k++)
							temp = temp + ";" + getResult(headings[k], j);
						peak_array = Array.concat(peak_array, temp);
					}
				}

				//measure overlap of particles with secondary channel
				run("Clear Results");
				roiManager("reset");
				prefix = findOverlap_noReset(part_file, "Particle");

				//add back peak data from temp array.
				for(j=0; j<peak_array.length; j++){
					row = peak_array[j];
					temp = split(row, ";");
					index = nResults;
					for(k=0; k<headings.length; k++)
						setResult(headings[k], index, temp[k]);
				}

				//save data to a file and delete the temp file created for peaks
				savepath1 = overlapFolder + save_primary + prefix + "_OVERLAP.xls";
				saveAs("Results", savepath1);
				File.delete(temp_file);
				close("*");		//close ROI Mask	
			}

			//make mask of primary channel
			run("Clear Results");
			roiManager("reset");
		
			if(data_type != "Both"){
				file1 = folder1 + file_list1[i];
				makeOverlapMask(width, height, slices, file1, data_type);
			}

			else{
				peak_file = peakFolder + peakFiles[i];
				part_file = particleROIFolder + particleFiles[i];

				//start mask with chan 1 particles
				makeOverlapMask(width, height, slices, part_file, "Particle");
			
				//extract non-overlapping peak positions from feature summary spreadsheet
				run("Clear Results");
				open(peak_file);
			
				for(j=0; j<nResults; j++){
					type = getResultString("TYPE", j);
	
					if(type == "Particle"){
						IJ.deleteRows(j,j);
						rows = nResults;
						j--;
					}
				}

				//add these areas to the ROI mask
				peakToROI(2);
				selectWindow("ROI MASK");
				roiManager("show all");
				roiManager("fill");	
			}
			
			//calc percent area for primary channel	
			if(job_getFeatPerArea){
				prefix = File.getName(cellROIs[i]);
				temp = split(prefix, ".");
				prefix = temp[0];
				savename = chanceFolder + prefix + "_" + chan1 + "_PERC AREA.xls";
				chanceColoc(savename, cellROIFolder + cellROIs[i]);
			}

			//find overlapping secondary channel features
			roiManager("reset");
			run("Clear Results");
		
			if(data_type2 != "Both"){
				file2 = folder2 + file_list2[i];
				prefix = findOverlap(file2, data_type2);
				savepath2 = overlapFolder + save_secondary + prefix + "_OVERLAP.xls";
				saveAs("Results", savepath2);
				close("*");		//close ROI Mask
			}

			else{
				peak_file2 = peakFolder2 + peakFiles2[i];
				part_file2 = particleROIFolder2 + particleFiles2[i];
			
				run("Clear Results");
				open(peak_file2);

				rows = nResults;
				for(j=0; j<rows; j++){
					type = getResultString("TYPE", j);
					if(type == "Particle"){
						IJ.deleteRows(j,j);
						rows = nResults;
						j--;
					}
				}

				//if there are peaks, find overlap and overwrite x,y coordinates.  Save to a temp array
				temp_file = overlapFolder + save_primary + "transformed-TEMP.xls";
				headings = newArray("Area", "X", "Y", "IntDen", "%Area", "RawIntDen", "Slice");
				peak_array = newArray;
				
				if(nResults > 0){
					saveAs("Results", temp_file);
					findOverlap(temp_file, "Peak");
				
					for(j=0; j<nResults; j++){
						temp = "" + getResult(headings[0], j);
						for(k=1; k<headings.length; k++)
							temp = temp + ";" + getResult(headings[k], j);
						peak_array = Array.concat(peak_array, temp);
					}
				}

				//measure overlap of particles with primary channel
				run("Clear Results");
				roiManager("reset");
				prefix = findOverlap_noReset(part_file2, "Particle");

				//add back peak data from temp array.
				for(j=0; j<peak_array.length; j++){
					row = peak_array[j];
					temp = split(row, ";");
					index = nResults;
					for(k=0; k<headings.length; k++)
						setResult(headings[k], index, temp[k]);
				}

				savepath2 = overlapFolder + save_secondary + prefix + "_OVERLAP.xls";
				saveAs("Results", savepath2);
				close("*");		//close ROI Mask	
				File.delete(temp_file);
			}

			//clean-up spreadsheets and calculate overlap distance
			roiManager("reset");
			run("Clear Results");
			run("Organize Overlap ", "find=[" + savepath1 + "]");
			run("Organize Overlap ", "find=[" + savepath2 + "]");

			if(data_type == "Both"){
				if(data_type2 == "Both"){
					run("Calc Overlap ", "chan1=[" + savepath1 + "] chan2=[" + peak_file2 + "]");
					run("Calc Overlap ", "chan1=[" + savepath2 + "] chan2=[" + peak_file + "]");
				}

				else{
					run("Calc Overlap ", "chan1=[" + savepath1 + "] chan2=[" + savepath2 + "]");
					run("Calc Overlap ", "chan1=[" + savepath2 + "] chan2=[" + peak_file + "]");
				}
			}

			else{
				if(data_type2 == "Both"){
					run("Calc Overlap ", "chan1=[" + savepath1 + "] chan2=[" + peak_file2 + "]");
					run("Calc Overlap ", "chan1=[" + savepath2 + "] chan2=[" + savepath1 + "]");
				}

				else{
					run("Calc Overlap ", "chan1=[" + savepath1 + "] chan2=[" + savepath2 + "]");
					run("Calc Overlap ", "chan1=[" + savepath2 + "] chan2=[" + savepath1 + "]");
				}	
			}
		}

		roiManager("reset");
		run("Clear Results");
	}

		
}

function summarizeFeatures(overlapFolder_peaks, overlapFolder_parts, saveFolder){
	//get file lists and instantiate data array	
	overlapFiles_peaks = getFileList(overlapFolder_peaks);
	overlapFiles_peaks = Array.sort(overlapFiles_peaks);
	overlapFiles_parts = getFileList(overlapFolder_parts);
	overlapFiles_parts = Array.sort(overlapFiles_parts);
	data_array = newArray;

	for(i=0; i<overlapFiles_peaks.length; i++){
		run("Clear Results");
		roiManager("reset");
		peak_file = overlapFiles_peaks[i];
		part_file = overlapFiles_parts[i];

		//get file prefix from particle overlap file
		prefix_split = split(part_file, "._");
		prefix = prefix_split[0] + "_" + prefix_split[1] + "_" + prefix_split[2] + "_" + prefix_split[3] + "_" + prefix_split[4];

		//load all particle data to data array
		open(overlapFolder_parts + part_file);
				
		for(j=0; j<nResults; j++){
			slice = getResult("slice", j);
			x = getResult("x", j);
			y = getResult("y", j);
			area = getResult("Area", j);
			if(area > 1){
				dataString = "Particle" + ";" + slice + ";" + x + ";" + y + ";" + area;
				data_array = Array.concat(data_array, dataString); 
			}	
		}

		//load relevant peak data to data array
		run("Clear Results");
		open(overlapFolder_peaks + peak_file);
				
		for(j=0; j<nResults; j++){
			bool = getResult("Colocalized?", j);
					
			if(bool == 0){
				slice = getResult("slice", j);
				x = getResult("x", j);
				y = getResult("y", j);
				area = getResult("Area", j);
				dataString = "Peak" + ";" + slice + ";" + x + ";" + y + ";" + area;
				data_array = Array.concat(data_array, dataString); 
			}
		}

		//load results table with data from data_array and save to an xls
		run("Clear Results");
		headers = newArray("TYPE", "slice", "x", "y", "Area");

		for(j=0; j<data_array.length; j++){
			data = split(data_array[j], ";");
			
			for(k=0; k<data.length; k++)
				setResult(headers[k], j, data[k]);
			
			setResult("Colocalized?", j, 1);
		}
		
		updateResults();
		saveAs("Results", saveFolder +  prefix + "_FEATURE SUMMARY.xls");

		//cleanup screen
		run("Clear Results");
		close("*");	
		data_array = newArray;
	}

	return;
}
		
//measures chance colocalization.  Assumes mask is already created and open
function chanceColoc(savePath, rois){
	
	run("Clear Results");
	updateResults();
	roiManager("reset");
	run("Set Measurements...", "area_fraction stack display redirect=None decimal=3");
		
	roiManager("open", rois);
	roiManager("Show All");
	roiManager("Measure");	//measure ROIs and add to Results Table
	
	for(i=0; i<nResults; i++)
		setResult("cell", i, getCell(i));

	updateResults();
	saveAs("Results", savePath);
	
	roiManager("reset");
	
	return;
}

function findOverlap(dataPath, dataType){
	//reset results table and roiManager
	roiManager("reset");
	run("Clear Results");
	updateResults();

	//open data file
	open(dataPath);
	prefix = File.nameWithoutExtension;	//extract experiment details from file name

	//draw rect. ROIs at peak positions
	x_array = newArray(nResults);
	y_array = newArray(nResults);
	
	if(dataType == "Peak"){
		temp = split(prefix, "-");
		prefix = temp[1] + "_PEAKS";

		for(i=0; i<nResults; i++){
			x_array[i] = getResult("x", i);
			y_array[i] = getResult("y", i);
		}
		
		peakToROI(2);
	}

	//measure intensity inside peak or particle ROIs
	run("Set Measurements...", "area centroid integrated area_fraction stack redirect=None decimal=3");
	roiManager("show all");
	roiManager("Measure");

	//overwrite x,y values with original peak positions
	if(dataType == "Peak"){
		for(i=0; i<x_array.length; i++){
			setResult("X", i, x_array[i]);
			setResult("Y", i, y_array[i]);
		}
	}

	return prefix;
}

function findOverlap_noReset(dataPath, dataType){
	//reset results table and roiManager
	run("Clear Results");
	updateResults();

	//open data file
	open(dataPath);
	name = File.nameWithoutExtension;	//extract experiment details from file name
	temp = split(name, "_");
	prefix = temp[0] + "_" + temp[1] + "_" + temp[2] + "_" + temp[3] + "_" + temp[4];

	//draw rect. ROIs at peak positions
	x_array = newArray(nResults);
	y_array = newArray(nResults);
	
	if(dataType == "Peak"){
		temp = split(prefix, "-");
		prefix = temp[1] + "_PEAKS";

		for(i=0; i<nResults; i++){
			x_array[i] = getResult("x", i);
			y_array[i] = getResult("y", i);
		}
		
		peakToROI(2);
	}

	//measure intensity inside peak or particle ROIs
	run("Set Measurements...", "area centroid integrated area_fraction stack redirect=None decimal=3");
	roiManager("show all");
	roiManager("Measure");

	//overwrite x,y values with original peak positions
	if(dataType == "Peak"){
		for(i=0; i<x_array.length; i++){
			setResult("X", i, x_array[i]);
			setResult("Y", i, y_array[i]);
		}
	}

	return prefix;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//loads multiple user defined images to an array
function loadImageArray(cellROIs){

	allImages = newArray;
	for(i=0; i<cellROIs.length; i++){
		image = File.openDialog(cellROIs[i]);
		allImages = Array.concat(allImages, image);
	}

	return allImages;
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//measures mean pixel intensities for pre-loaded ROIs and saves to indicated path
function getPixelInts(savePath){
	run("Clear Results");
	updateResults();
	
	run("Set Measurements...", "mean stack display redirect=None decimal=3");	//only measure mean and stack position
	roiManager("Show All");
	roiManager("Measure");	//measure ROIs and add to Results Table
	for(i=0; i<nResults; i++)
		setResult("cell", i, getCell(i));	//add cell number to results table

	saveAs("Results", savePath);	//save values to designated path
	selectWindow("Results");
	run("Close");
}

//extracts cell number from ROI label
function getCell(i){
	label = getResultString("Label", i);
	split1 = split(label, ":-");
	cell = parseInt(split1[2]);
	return cell;

}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//assumes image and cell ROIs are already open
function getCellFeats(dataType, imageTitle, savePath){

	run("Clear Results");
	updateResults();
	
	if(dataType == "Peak"){
		//use peak fitter to pick peaks inside cell ROIs
		if(settings.length == 0)
			settings = getPeakSettings(); //Ask user for peak picking parameters
		selectWindow(imageTitle);
		run("Peak Fitter", "use_discoidal_averaging_filter inner_radius=" + settings[0] + " outer_radius=" + settings[1] + " threshold="+ settings[2] + " threshold_value=" + settings[3] + " minimum_distance=" + settings[4] + " fit_radius=" + settings[5] + " max_error_baseline=5000 max_error_height=5000 max_error_x=1 max_error_y=1 max_error_sigma_x=1 max_error_sigma_y=1 fit_peaks_inside_rois stack");
		saveAs("Results", savePath);
	}

	if(dataType == "Particle"){
		//make an ROI mask which only includes areas of flat cells
		selectWindow(imageTitle);
		width = getWidth();
		height = getHeight();
		numSlice = nSlices();
		newImage("ROI MASK", "16-bit black", width, height, numSlice);	//make blank stack of correct size and depth
		roiManager("Fill");		
		run("Divide...", "value=65535.000 stack");	//normalize intensities (0-1)

		//Apply ROI mask to Original Image so that only intensities within flat cells is left.
		imageCalculator("Multiply create stack", imageTitle, "ROI MASK");
		flatImage = getTitle();
		close("ROI MASK");

		//Get threshold parameters from user
		if(thresh.length == 0){
			Dialog.create("");
			Dialog.addMessage("Seperate values with a space");
			Dialog.addString("Relevant Frames: ", "1 3 5 7 9 11 13", 50);
			Dialog.addString("Intensity Range: ", "0 2300", 50);
			Dialog.addString("8-bit Threshhold Settings: ", "175 255", 50);
			Dialog.show();

			frames = split(Dialog.getString(), " ");
			i_range = split(Dialog.getString(), " ");
			thresh = split(Dialog.getString(), " ");
		}
		//Array.print(i_range);
		
		//Apply threshold settings to make particle mask then make ROIs around particles
		run("Options...", "iterations=1 count=1 black");
		makeROIs(flatImage, frames, i_range, thresh, savePath);
	}
}

//Dialog box to get peak fitter settings from user
function getPeakSettings(){
	Dialog.create("");
	Dialog.addMessage("Peak Picking Settings");
	Dialog.addNumber("Inner Radius: ", 1);//1
	Dialog.addNumber("Outer Radius: ", 8);//4
	Dialog.addNumber("Threshold (mean + n STDEV): ", 6);
	Dialog.addNumber("Threshold: ", 0);//250
	Dialog.addNumber("Min Radius: ", 4);//4
	Dialog.addNumber("Fit Radius: ", 3);//4
	Dialog.show();

	inner = Dialog.getNumber();
	outer = Dialog.getNumber();
	mean_thr = Dialog.getNumber();
	thr = Dialog.getNumber();
	rad = Dialog.getNumber();
	fit = Dialog.getNumber();

	result = newArray(inner, outer, mean_thr, thr, rad, fit);
	return result;
	
}

//makes particles from particle mask with minimum ROI size of 16
function makeROIs(stack, frames, iRange, thresholds, savePath){
	roiManager("reset");	//reset manager
	selectWindow(stack);
	run("Discoidal Averaging Filter", "inner_radius=1 outer_radius=8 stack");
	setMinAndMax(parseInt(iRange[0]), parseInt(iRange[1]));
	run("8-bit");
	
	//Apply thresholds to frames to create a mask
	for(i=0; i<frames.length; i++){
		f = frames[i];
		if(parseInt(f) <= numSlice){
			setSlice(f);
			setThreshold(parseInt(thresholds[0]), parseInt(thresholds[1]));
			run("Convert to Mask", "method=Default background=Dark only black");
		}

		else
			i=frames.length;
	}

	run("Analyze Particles...", "size=16-1000 include add stack");	//make ROIs from mask and add to ROI Manager
	if(roiManager("count") == 0){
		makeRectangle(0,0,1,1);
		roiManager("add");
	}
	
	roiManager("save", savePath);	//save ROIs to a zip archive
	close(stack);	//close mask

	return;
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//measures pixel intensity of a particle ROI
function measureParticles(stack, savePath){
	selectWindow(stack);
	run("Set Measurements...", "area mean min centroid bounding shape integrated stack redirect=None decimal=3");
	roiManager("Show All without labels");
	roiManager("Measure");
	saveAs("Results", savePath);
	run("Organize Particles ", "find=[" + savePath + "]");
	return;	
}

//measures pixel intensity inside an ROI drawn at a peak location
function measurePeaks(stack, peakPath){
	//draw ROIs at peak locations
	roiManager("reset");
	peakToROI(2);

	//measure peak intensities
	run("Clear Results");
	updateResults;
	
	run("Set Measurements...", "mean integrated stack redirect=None decimal=3");
	selectWindow(stack);
	roiManager("Show All without labels");
	roiManager("Measure");

	//save intensity information to arrays
	intDen_array = newArray;
	mean_array = newArray;
	for(i=0; i<nResults; i++){
		intDen_array = Array.concat(intDen_array, getResult("IntDen", i));
		mean_array = Array.concat(mean_array, getResult("Mean", i));
	}

	//update peak spreadsheet with peak intensity data and re-save
	run("Clear Results");
	updateResults();
	open(peakPath);
	for(i=0; i<nResults; i++){
		setResult("IntDen", i, intDen_array[i]);
		setResult("Mean Int", i, mean_array[i]);
	}
	
	updateResults();
	saveAs("Results", peakPath);
}	

//makes rectangular ROIs at x,y coordinates given in results table
function peakToROI(rad){
	
	for(i = 0; i<nResults; i++){
		slice = getResult("slice", i);
		x = getResult("x", i);
		y = getResult("y", i);

		//draw circle of radius "rad" centered at gaussian center
		setSlice(slice);
		x2 = parseFloat(x - rad);
		y2 = parseFloat(y - rad);
		makeRectangle(x2, y2, 2*rad, 2*rad);
		roiManager("add");
	}
	
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//asks user for overlap calculation settings and location of secondary channel data
function getOverlapSettings(){
	Dialog.create("");
	Dialog.addMessage("Stack Parameters");
	Dialog.addNumber("Width: ", 7000);
	Dialog.addNumber("Height: ", 7000);
	Dialog.addNumber("Slices: ", 13);
	Dialog.addMessage("Secondary Imaging Channel");
	Dialog.addNumber("Wavelength: ", 568);
	Dialog.addRadioButtonGroup("Data Type: ", newArray("Peak","Particle", "Both"),1,3, "Peak");
	Dialog.show(); 

	width = Dialog.getNumber();
	height = Dialog.getNumber();
	slices = Dialog.getNumber();

	//set global variables
	settings = newArray(width, height, slices);
	chan2 = Dialog.getNumber();
	data_type2 = Dialog.getRadioButton();

	return;
}

//generates overlap sub folder names according to data type and imaging channel
function nameFolder (channel1, datatype1, channel2, datatype2){
	folder = "";
	if(datatype1 == "Peak"){
		if(datatype2 == "Peak")
			folder = "" + channel1 + " PEAKS TO " + channel2 + " PEAKS\\";
		else if(datatype2 == "Particle")
			folder = "" + channel1 + " PEAKS TO " + channel2 + " PARTICLES\\";
		else
			folder = "" + channel1 + " PEAKS TO " + channel2 + "\\";
	}

	else if(datatype1 == "Particle"){
		if(datatype2 == "Peak")
			folder = "" + channel1 + " PARTICLES TO " + channel2 + " PEAKS\\";
		else if(datatype2 == "Particle")
			folder = "" + channel1 + " PARTICLES TO " + channel2 + " PARTICLES\\";
		else
			folder = "" + channel1 + " PARTICLES TO " + channel2 + "\\";
	}

	else{
		if(datatype2 == "Peak")
			folder = "" + channel1 + " TO " + channel2 + " PEAKS\\";
		else if(datatype2 == "Particle")
			folder = "" + channel1 + " TO " + channel2 + " PARTICLES\\";
		else
			folder = "" + channel1 + " TO " + channel2 + "\\";
	}

	return folder;
}

/* draws overlap mask for given data sets
   dataArray is array of data filepaths
   datatypeArray is an array of corresponding data types (peak or particle) for the given data sets*/
function makeOverlapMask(w, h, num_slice, dataFile, datatype){
	newImage("ROI MASK", "8-bit black", w, h, num_slice);	
	
	roiManager("reset");
	run("Clear Results");
	updateResults();

	open(dataFile);
		
	if(datatype == "Peak")
		peakToROI(2);

	roiManager("show all");
	roiManager("fill");	
	
}

function addPeaksToMask(dataArray){
	selectWindow("ROI MASK");
	
	roiManager("reset");	
	peakToROI(2);

	roiManager("show all");
	roiManager("fill");	
	
}
