var chan2_slice = newArray;
var chan2_x = newArray;
var chan2_y = newArray;

macro Calc_Overlap{

	chan1_file = File.openDialog("Chan1 File");
	chan2_file = File.openDialog("Chan2 File");

	run("Clear Results");
	updateResults;

	//load channel 2 colocalized particles to arrays
	open(chan2_file);
	updateResults();
	rows = nResults;
	for(i=0; i<rows; i++){
		coloc = getResult("Colocalized?", i);
		if(coloc == 1){
			chan2_slice = Array.concat(chan2_slice, getResult("slice", i));
			chan2_x = Array.concat(chan2_x, getResult("x", i));
			chan2_y = Array.concat(chan2_y, getResult("y", i));
		}
	}

	run("Clear Results");
	updateResults;

	//Load channel 1 file and process distances
	open(chan1_file);
	rows = nResults;

	for(i=0; i<rows; i++){
		coloc = getResult("Colocalized?", i);

		//if not colocalized set distance to -1
		if(coloc == 0)
			setResult("distance", i, -1);

		//if colocalized find the minimum centroid to centroid distance
		else{
			slice = getResult("slice", i);
			x = getResult("x", i);
			y = getResult("y", i);

			d = minDist(slice, x, y);
			setResult("distance", i, d);
		}
	}

	saveAs("Results", chan1_file);
}

//find minimum centroid distance
function minDist(slice1, x1, y1){

	indexes = findIndexes(slice1, chan2_slice);
	xArray = trimArray(indexes, chan2_x);
	yArray = trimArray(indexes, chan2_y);
	
	dist = -2;
//	if(getResult("distance", row) != -2)
//		dist = getResult("distance", row);

	for(i=0; i<indexes.length; i++){
		x2 = xArray[i];
		y2 = yArray[i];
		d = distCalc(x1, y1, x2, y2);

		if(dist == -2)
			dist = d;
		if(d < dist)
			dist = d;
	}

	return dist;
}

//find indexes in an array with a particular item 
function findIndexes(key, array){
	  indexes = newArray;

	  for(i=0; i<array.length; i++){
	  	if(array[i] == key)
	  		indexes = Array.concat(indexes, i);
	  }

	  return indexes;
	
}

//given indexes and an array, return a trimmed array containing contents of that array
//only at the indicated indexes
function trimArray(indexes, array){
	subArray = newArray(array.length);	
	
	for(i=0; i<indexes.length; i++){
		index = indexes[i];
		subArray[i] = array[index];
	}

	return subArray;
}

//calculate distance between two (x,y) coordinates
function distCalc(x1, y1, x2, y2){
	dx = x1 - x2;
	dy = y1 - y2;

	distance = sqrt((dx*dx) + (dy*dy));
	return distance;
}
