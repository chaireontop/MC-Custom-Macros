var prefix;

macro Plot_Peaks{

	Dialog.create("");
	Dialog.addString("SAVE PREFIX ", "DATE_TIME_DESC",20);
	Dialog.show();
	prefix = Dialog.getString();

	
	path = File.openDialog("Find peak spreadsheet");
	open(path);
	root = File.directory();

	path = File.openDialog("Open stack in which peak intensities should be measured.");
	open(path);
	fileName = File.nameWithoutExtension;
	
	rows = getValue("results.count");
	for(i=0; i<rows; i++){
		x = getResult("x", i);
		y = getResult("y", i);
		
		makeRectangle(x-2.5, y-2.5, 5, 5);
		roiManager("add");
	}

	run("Clear Results");
	updateResults();
	run("Enhance Contrast", "saturated=0.35");
	roiManager("show all");
	//run("Set Measurements...", "mean stack redirect=None decimal=3");
	//roiManager("Multi Measure");
	removeBackground();
	saveName = prefix + "_" + fileName + "_PEAK INTS";
	saveAs("Results", root + saveName  + ".xls");
	
}

// helper functions
function selectRectangle(x, y, radius) {
	w = radius * 2 + 1;
	makeRectangle(x - radius, y - radius, w, w);
}

function selectCircle(x, y, radius) {
	w = radius * 2 + 1;
	makeOval(x - radius, y - radius, w, w);
}


function select(shape, x, y, radius) {
	
	if (shape == "rectangle")
		selectRectangle(x, y, radius);
	else
		selectCircle(x, y, radius);
		
}

function getMeasurementValue(shape, measurement, x, y, radius) {
	select(shape, x, y, radius);
	List.setMeasurements;
	return List.get(measurement);
}


function removeBackground(){
	
	items = newArray("rectangle", "circle");
	measurements = newArray(6);
	measurements[0] = "Mean";
	measurements[1] = "StdDev";
	measurements[2] = "Min";
	measurements[3] = "Max";
	measurements[4] = "IntDen";
	measurements[5] = "RawIntDen";


	Dialog.create("Peak Intensity");
	Dialog.addNumber("inner_radius", 2);
	Dialog.addNumber("outer_radius", 4);
	Dialog.addChoice("shape", items);
	Dialog.addChoice("measurement", measurements);
	Dialog.addString("expression", "a-b");
	Dialog.show;

	inner_radius = Dialog.getNumber;
	outer_radius = Dialog.getNumber;
	shape = Dialog.getChoice;
	measurement = Dialog.getChoice;
	expression = Dialog.getString;

	n = roiManager("count");

	// get all slice position because of buggy roi manager
	cx = newArray(n);
	cy = newArray(n);

	for (i = 0; i < n; i++) {
		roiManager("select", i);
		getSelectionBounds(x, y, width, height);
		cx[i] = x + floor(width / 2);
		cy[i] = y + floor(height / 2);
	}

	run("Set Measurements...", "mean standard modal min integrated redirect=None decimal=3");

	for (slice = 1; slice <= nSlices; slice++) {
	
		setSlice(slice);
	
		for (i = 0; i < n; i++) {
		
			I_inner = getMeasurementValue(shape, measurement, cx[i], cy[i], inner_radius);
			I_outer = getMeasurementValue(shape, measurement, cx[i], cy[i], outer_radius);
		
			expr = "a=" + I_inner + ";b=" + I_outer + ";return toString(" + expression + ");";
			result = eval(expr);
		
			row = slice - 1;
			setResult(measurement + "_" + i, row, result);
		}
	}
}



