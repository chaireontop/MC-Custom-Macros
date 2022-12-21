/*
 * Created by Megan E. Cherry
 * Last Update: 11/17/2020
 * 
 * Macro is responible for sorting/ converting nd2 image files to name standardized TIFF files.  
 * Raw tiffs are then further processed and corrected by called helper macros.
 * 
 * Called Macros:
 * 	"Interval Process Images "
 * 	"RA Process Images "
 * 	"TL Process Images "
 * 	
 * Designed for below experiment types:
 * 	Interval Imaging
 * 	Rapid/ Continuous Imaging
 * 	Time-lapse Imaging
 * 	Multi-position Snapshots
 */

var convert = false;
var sort = false;
var verify = false;
var consolidate = false;
var sortUV = false;
var allChans = "";

macro Process_Raw_Images_{

	//prompt user for experiment type
	Dialog.create("");
	Dialog.addMessage("What type of experiment was run?");
	Dialog.addRadioButtonGroup("", newArray("INTERVAL IMAGING", "RAPID ACQUISITION", "SNAPSHOTS", "TIME-LAPSE"), 4, 1, "TIME-LAPSE");
	Dialog.show();
	choice = Dialog.getRadioButton();

	//prompt user for what actions are needed (corting, converting, etc.)
	getActions(choice); 
	
	//For Interval Imaging experiments
	//Will sort and/or convert original ND2 files into name-standardized TIFF files.  Calls "Interval Process Images " macro.
	if(choice == "INTERVAL IMAGING"){
	
		if(sort || convert){
			//get experimental root folder from user and make a directory for tiffs
			rootFolder = getDirectory("Choose/ create a root folder");
			outputFolder = rootFolder + "_ORIGINAL\\";
			File.makeDirectory(outputFolder);
			
			//ask user for imaging channels, save to an array
			Dialog.create("");
			Dialog.addMessage("List the imaging channels in order of acquisition.\n Seperate multiple channels with a semi-colon.");
			Dialog.addString("  ", "BF;514");
			Dialog.show();
			allChans = split(Dialog.getString(), ";");

			//ask user for location of raw nd2 files, get a list of files, then sort into channel folders.  Soring assignment is determined by "Seq" number, thus channel labels must be entered in acquisition order.
			if(sort){
				ndFolder = getDirectory("Where are ND2 Files stored?");
				allFiles = getFileList(ndFolder);

				for(i=0; i<allChans.length; i++){
					channel = allChans[i];
					chanFolder = ndFolder + "" + channel + "\\";
					File.makeDirectory(chanFolder);

					for(j=0; j<allFiles.length; j++){
						file = allFiles[j];
						sFile = split(file, "Seq");
						sFile = split(sFile[1], ".");
						seq_num = parseInt(sFile[0]);

						if(seq_num % allChans.length == i)
							File.rename(ndFolder + file, chanFolder + file);
					}		

					//convert sorted nd2 files to TIFF format using name convention "Position# Channel.tif"
					if(convert){
						convertToTiff(true, channel, chanFolder, outputFolder);
					}
				}	
				
				convert = false;
			}

			//converts nd2 files into TIFF files.  User is asked for channel folder locations.
			if(convert){
				for(i=0; i<allChans.length; i++){
					channel = allChans[i];
					inputFolder = getDirectory("Find folder of ND2 FILES for " + channel);
					convertToTiff(true, channel, inputFolder, outputFolder);
				}
			}
		}
		
		run("Interval Process Images ");
	}

	//For Continuous/ Rapid Acquisition Imaging experiments
	//Will convert original ND2 files into name-standardized TIFF files.  Calls "RA Process Images " macro.
	//Assumes that nd2 files have been organized into channel specific folders
	else if(choice == "RAPID ACQUISITION"){
		if(convert){
			rootFolder = getDirectory("Choose/ create a root folder");
			outputFolder = rootFolder + "_ORIGINAL\\";
			File.makeDirectory(outputFolder);
		
			for(i=0; i<allChans.length; i++){
				channel = allChans[i];
				inputFolder = getDirectory("Find folder of ND2 FILES for " + channel);
				convertToTiff(true, channel, inputFolder, outputFolder);
			}
		}

		run("RA Process Images  ");
	}

	//For snapshots taken of multiple positions at one time point
	//Will convert original ND2 files into name-standardized TIFF files.  Calls "TL Process Images " macro.
	//Assumes that images stacks should be split
	else if(choice == "SNAPSHOTS"){
		if(convert){
			rootFolder = getDirectory("Choose/ create a root folder");
			outputFolder = rootFolder + "_ORIGINAL\\";
			File.makeDirectory(outputFolder);
			for(i=0; i<allChans.length; i++){
				channel = allChans[i];
				inputFile = File.openDialog("Find ND2 file for " + channel);
				convertToTiff(false, channel, inputFile, outputFolder);
			}
		}
		
		run("TL Process Images ");
	}

	//For Time-Lapse experiments
	//Will sort and/or convert original ND2 files into name-standardized TIFF files.  Calls "TL Process Images " macro.
	//Assumes that images are stacked by position
	else{		
		if(sort || convert){
			rootFolder = getDirectory("Choose/ create a root folder");
			outputFolder = rootFolder + "_ORIGINAL\\";
			File.makeDirectory(outputFolder);

			Dialog.create("");
			Dialog.addMessage("List the imaging channels in order of acquisition.\n Seperate multiple channels with a semi-colon.");
			Dialog.addString("  ","BF;514");
			Dialog.show();

			allChans = split(Dialog.getString(),";");
			ndFolder = "";

			if(sort){
				//ask user for location of raw nd2 files, get a list of files, then sort into channel folders.  Sorting assignment is determined by "Seq" number, thus channel labels must be entered in acquisition order.
				ndFolder = getDirectory("Where are ND2 Files stored?");
				allFiles = getFileList(ndFolder);

				for(i=0; i<allChans.length; i++){
					channel = allChans[i];
					chanFolder = ndFolder + "" + channel + "\\";
					File.makeDirectory(chanFolder);

					for(j=0; j<allFiles.length; j++){
						file = allFiles[j];
						sFile = split(file, "q");
						sFile = split(sFile[1], ".");
						seq_num = parseInt(sFile[0]);
						
						if(seq_num % allChans.length == i)
							File.rename(ndFolder + file, chanFolder + file);
					}
				}
			}	

			//convert nd2 files to name-standardized TIFFs.  IF a UV experiment, add denote post-UV images by adding a "2" to the channel label
			if(convert){	
				if(sortUV){
					for(i=0; i<allChans.length; i++){
						channel = allChans[i];
						preUV = File.openDialog("Find the PRE-UV ND2 file for " + channel);
						postUV = getDirectory("Find folder of POST-UV ND2 files for " + channel);
						convertToTiff(false, channel, preUV, outputFolder);
						convertToTiff(true, channel + "2", postUV, outputFolder);
					}
				}

				else{
					for(i=0; i<allChans.length; i++){
						channel = allChans[i];

						if(sort)
							inputFolder = ndFolder + "" + channel + "\\";
						else
							//if sorting dialog was not run, ask user for channel folders
							inputFolder = getDirectory("Find folder for " + channel + " ND2 FILES");
						convertToTiff(true, channel, inputFolder, outputFolder);
					}
				}	
			}
		}

		run("TL Process Images ");
	}

	//macro restart dialog
	Dialog.create("");
	Dialog.addMessage("Process more experiments?");
	Dialog.addChoice("",newArray("yes", "no"), "yes");
	Dialog.show();

	if(Dialog.getChoice() == "yes"){
		run("Process Raw Images ");
	}
}

//HELPER FUNCTIONS#####################################################

//Ask user what actions should be carried out on nd2 files.  Dialog that appears is experiment dependent.
function getActions(choice){
	if(choice == "INTERVAL IMAGING"){
		Dialog.create("IS ANY PRE-PROCESSING REQUIRED?");
		Dialog.addCheckbox("Sort ND2 files?", true);
		Dialog.addCheckbox("Convert ND2 files to TIFF files?", true);
		Dialog.show();
		sort = Dialog.getCheckbox();
		convert = Dialog.getCheckbox();
		return;
	}
	
	if(choice == "RAPID ACQUISITION"){
		Dialog.create("IS ANY PRE-PROCESSING REQUIRED?");
		Dialog.addCheckbox("Convert ND2 files to TIFF files?", false);
		Dialog.addMessage("What fluorescence channel(s) need to be processed?\n Seperate multiple channels with a semi-colon.");
		Dialog.addString("  ","514");
		Dialog.show();
		convert = Dialog.getCheckbox();
		allChans = split(Dialog.getString(),";");
		return;
	}
	
	if(choice == "SNAPSHOTS"){
		Dialog.create("IS ANY PRE-PROCESSING REQUIRED?");
		Dialog.addCheckbox("Convert ND2 files to TIFF files?", false);
		Dialog.addCheckbox("Consolidate multiple folders?", false);
		Dialog.addMessage("What channel(s) need to be processed?\n Seperate multiple channels with a semi-colon.");
		Dialog.addString("  ","BF");
		Dialog.show();
		convert = Dialog.getCheckbox();
		consolidate = Dialog.getCheckbox();
		allChans = split(Dialog.getString(),";");
		return;
	}
	
	if(choice == "TIME-LAPSE"){
		Dialog.create("IS ANY PRE-PROCESSING REQUIRED?");
		Dialog.addCheckbox("Sort ND2 files?", false);
		Dialog.addCheckbox("Convert ND2 files to TIFF files?", false);
		Dialog.addCheckbox("Process Pre/Post UV Images", false);
		Dialog.show();
		sort = Dialog.getCheckbox();
		convert = Dialog.getCheckbox();
		sortUV = Dialog.getCheckbox();
		return;
	}
}

//Converts nd2 files to name-standardized TIFF files.  Takes a boolean parameter which indicates whether nd2 files should be kept as a stack or saved as individual images
function convertToTiff(bool, channel, inputDirectory, outputFolder){
	
	//if stacks should stay stacks (time-lapse, rapid acquisition, interval imaging) open nd2 files, rename, and save as TIFF
	if(bool){
		allFiles = getFileList(inputDirectory);
		allFiles = Array.sort(allFiles);
		for(i=0; i<allFiles.length; i++){
			path = inputDirectory + allFiles[i];
			run("Bio-Formats Importer", "open=[" + path + "]" + " color_mode=Default" + " concatenate_series" + " open_all_series rois_import=[ROI manager]" + " view=Hyperstack stack_order=XYCZT");

			//format image number
			number = i+1;
			pos = "";
			if(number < 10)
				pos = "00" + number;
			else
				pos = "0" + number;
			saveAs("tiff", outputFolder + pos + " " + channel + ".tif");
			close();
		}	
	}

	//if stacks should be split then saved, open nd2 frames as seperate images, rename, and save as TIFFs
	else{
		path = inputDirectory;
		run("Bio-Formats Importer", "open=[" + path + "]" + " color_mode=Default" + " open_all_series rois_import=[ROI manager]" + " view=Hyperstack stack_order=XYCZT");
		last = getPosition(getTitle());
		for(i=0; i<last; i++){
			pos = "0" + getPosition(getTitle());
			if(lengthOf(pos) == 2)
				pos = "0" + pos;
			saveAs("tiff", outputFolder + pos + " " + channel + ".tif");
			close();
		}
	}
}

//extracts position number from nd2 file image title
function getPosition(string){
	x_split = split(string, "series )");
	pos = x_split[lengthOf(x_split) -1];
	return pos;
}


