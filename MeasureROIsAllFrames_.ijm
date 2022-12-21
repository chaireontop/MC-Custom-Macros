/*
 * Created on February 1, 2017 by Megan E. Cherry
 * 
 */
macro MeasureROIs{
	roiFolder = getDirectory("Where are ROI folders located?");
	imageFolder = getDirectory("Where are images located?");
	
	allROIs = getFileList(roiFolder);
	allImages = getFileList(imageFolder);

	//Check if there is an ROI folder for each image.  If not, alert the user.
	if(allROIs.length != allImages.length){
		Dialog.create("Error");
		Dialog.addMessage("Both folders must contain the same number of files.");
		Dialog.addMessage("Please try again.");
		Dialog.show();
	}

	else{
		run("Set Measurements...", "mean integrated median stack display redirect=None decimal=3");

		//Measure intensity statistics of ROIs in each image
		for (i=0; i<allImages.length; i++){
			open(allImages[i]);
			roiManager("open", roiFolder + allROIs[i]);
			roiManager("sort");
			roiManager("remove slice info");

			for(j=1; j<=nSlices; j++){
				setSlice(j);
				roiManager("measure");
			}

			roiManager("reset");
			close();
			
		}

		//Clean-up Results Table
		rows = getValue("results.count");

		for (i=0; i<rows; i++){
			label_full = getResultString("Label", i);
			label_split = split(label_full, "- :");
			image_num = parseInt(label_split[0]);
			cell_num = parseInt(label_split[3]);
			setResult("image #", i, image_num);
			setResult("cell", i , cell_num);
		}	
		updateResults();
	}
}
