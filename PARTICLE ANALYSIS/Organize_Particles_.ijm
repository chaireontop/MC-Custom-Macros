/*
 * Organizes results table after Measure_SSB_ macro is run.
 */

macro Organize_Particles_{

	results = File.openDialog("Find spreadsheet");
	run("Clear Results");
	updateResults;
	
	open(results);
	rows = nResults;

	//instantiate temp arrays
	tArea = newArray;
	tMean = newArray;
	tMin = newArray;
	tMax = newArray;
	tX = newArray;
	tY = newArray;
	tBX = newArray;
	tBY = newArray;
	tWidth = newArray;
	tHeight = newArray;
	tIntDen = newArray;
	tSlice = newArray;
	circ = newArray;

	//load temp arrays with results table data
	for(i=0; i<rows; i++){
		tArea = Array.concat(tArea, getResult("Area", i));
		tMean = Array.concat(tMean, getResult("Mean", i));
		tMin = Array.concat(tMin, getResult("Min", i));
		tMax = Array.concat(tMax, getResult("Max", i));
		tX = Array.concat(tX, getResult("X", i));
		tY = Array.concat(tY, getResult("Y", i));
		tBX = Array.concat(tBX, getResult("BX", i));
		tBY = Array.concat(tBY, getResult("BY", i));
		tWidth = Array.concat(tWidth, getResult("Width", i));
		tHeight = Array.concat(tHeight, getResult("Height", i));
		tIntDen = Array.concat(tIntDen, getResult("IntDen", i));
		tSlice = Array.concat(tSlice, getResult("Slice", i));
		circ = Array.concat(circ, getResult("Circ.", i));
	}

	//Instantiate new array variables with correct size
	area = newArray(rows);
	mean = newArray(rows);
	min = newArray(rows);
	max = newArray(rows);
	x = newArray(rows);
	y = newArray(rows);
	bx = newArray(rows);
	by = newArray(rows);
	width = newArray(rows);
	ht = newArray(rows);
	intDen = newArray(rows);
	slice = newArray(rows);
	circ2 = newArray(rows);

	//sort by area
	ranks = Array.rankPositions(tArea);
	for(i=0; i<rows; i++){
		index = ranks[i];
		
		area[i] = tArea[index];
		mean[i] = tMean[index];
		min[i] = tMin[index];
		max[i] = tMax[index];
		x[i] = tX[index];
		y[i] = tY[index];
		bx[i] = tBX[index];
		by[i] = tBY[index];
		width[i] = tWidth[index];
		ht[i] = tHeight[index];
		intDen[i] = tIntDen[index];
		slice[i] = tSlice[index];
		circ2[i] = circ[index];
	}

	//reset temp and storage arrays
	tArea = Array.copy(area);
	tMean = Array.copy(mean);
	tMin = Array.copy(min);
	tMax = Array.copy(max);
	tX = Array.copy(x);
	tY = Array.copy(y);
	tBX = Array.copy(bx);
	tBY = Array.copy(by);
	tWidth = Array.copy(width);
	tHeight = Array.copy(ht);
	tIntDen = Array.copy(intDen);
	tSlice = Array.copy(slice);
	circ = Array.copy(circ);

	area = newArray(rows);
	mean = newArray(rows);
	min = newArray(rows);
	max = newArray(rows);
	x = newArray(rows);
	y = newArray(rows);
	bx = newArray(rows);
	by = newArray(rows);
	width = newArray(rows);
	ht = newArray(rows);
	intDen = newArray(rows);
	slice = newArray(rows);
	circ2 = newArray(rows);

	//sort by slice
	ranks = Array.rankPositions(tSlice);
	for(i=0; i<rows; i++){
		index = ranks[i];
		
		area[i] = tArea[index];
		mean[i] = tMean[index];
		min[i] = tMin[index];
		max[i] = tMax[index];
		x[i] = tX[index];
		y[i] = tY[index];
		bx[i] = tBX[index];
		by[i] = tBY[index];
		width[i] = tWidth[index];
		ht[i] = tHeight[index];
		intDen[i] = tIntDen[index];
		slice[i] = tSlice[index];
		circ2[i] = circ[index];
	}

	run("Clear Results");
	updateResults;

	for(i=0; i<rows; i++){

		setResult("Slice", i, slice[i]);
		setResult("X", i, x[i]);
		setResult("Y", i, y[i]);
		setResult("Area", i, area[i]);
		setResult("IntDen", i, intDen[i]);
		setResult("Mean", i, mean[i]);
		setResult("Min", i, min[i]);
		setResult("Max", i, max[i]);
		setResult("BX", i, bx[i]);
		setResult("BY", i, by[i]);
		setResult("Width", i, width[i]);
		setResult("Height", i, ht[i]);
		setResult("Circ.", i, circ2[i]);
	}	

	updateResults;
	saveAs("Results", results);
	run("Close");




	
}
