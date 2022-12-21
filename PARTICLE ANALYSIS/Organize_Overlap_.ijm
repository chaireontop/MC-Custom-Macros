
macro Organize_Overlap_{
	
	results = File.openDialog("Find spreadsheet");
	run("Clear Results");
	updateResults;
	
	open(results);
	rows = nResults;

	//instantiate temp arrays
	tArea = newArray(rows);
	tX = newArray(rows);
	tY = newArray(rows);
	tPerArea = newArray(rows);
	tSlice = newArray(rows);
	tColoc = newArray(rows);

	//load temp arrays with results table data
	for(i=0; i<rows; i++){
		
		tArea[i] = getResult("Area", i);
		tX[i] = getResult("X", i);
		tY[i] = getResult("Y",i);
		tPerArea[i] = getResult("%Area", i);
		tSlice[i] = getResult("Slice", i);

		if(tPerArea[i] == 0)
			tColoc[i] = 0;
		else
			tColoc[i] = 1;
	}

	//Instantiate global array variables with correct size
	area = newArray(rows);
	x = newArray(rows);
	y = newArray(rows);
	perArea = newArray(rows);
	slice = newArray(rows);
	coloc = newArray(rows);
	ranks = newArray(rows);

	//sort rows by colocalization and add to global arrays
	ranks = Array.rankPositions(tColoc);
	ranks = Array.reverse(ranks);
	for(i=0; i<rows; i++){
		index = ranks[i];
		
		area[i] = tArea[index];
		x[i] = tX[index];
		y[i] = tY[index];
		perArea[i] = tPerArea[index];
		slice[i] = tSlice[index];
		coloc[i] = tColoc[index];
	}

	//reset temp and global arrays
	tArea = Array.copy(area);
	tX = Array.copy(x);
	tY = Array.copy(y);
	tPerArea = Array.copy(perArea);
	tSlice = Array.copy(slice);
	tColoc = Array.copy(coloc);

	area = newArray(rows);
	x = newArray(rows);
	y = newArray(rows);
	perArea = newArray(rows);
	slice = newArray(rows);
	coloc = newArray(rows);

	//sort rows by slice number and add to global arrays
	ranks = Array.rankPositions(tSlice);
	for(i=0; i<rows; i++){
		index = ranks[i];
		
		area[i] = tArea[index];
		x[i] = tX[index];
		y[i] = tY[index];
		perArea[i] = tPerArea[index];
		slice[i] = tSlice[index];
		coloc[i] = tColoc[index];
		
	}
	
	run("Clear Results");
	updateResults;

	for(i=0; i<rows; i++){

		setResult("slice", i, slice[i]);
		setResult("x", i, x[i]);
		setResult("y", i, y[i]);
		setResult("Area", i, area[i]);
		setResult("Colocalized?", i, coloc[i]);
		setResult("%Area", i, perArea[i]);
		
	}

	updateResults;
	saveAs("Results", results);

	
}
