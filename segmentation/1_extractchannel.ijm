' Make a substack of channels with optional 2x scale.

var setname;
var setchan;
var numchan;
var scale;
var batch;
var zstart;
var zend;
var maxproj;
dialoggen();

setBatchMode(true);
numchan = lengthOf(setchan);
arg = build_arg();

if (batch) {
	dir = getDirectory("Choose a Directory");
	list = getFileList(dir);
	File.makeDirectory(dir + setname + "/");
	
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], ".tif")) {
			open(dir + list[i]);
			process();
			saveAs(dir + setname + "/" + setname + "_" + list[i]);
			run("Close All");
		}
	}
} else {
	name = getTitle();
	process();
	rename(setname + "_" + name);
	setBatchMode("show");
}


function dialoggen() {
	Dialog.create("Channel Reduction");
	Dialog.addString("Name", "Sox9");
	Dialog.addMessage("Name of the output channel(s).\nBy default, files will be saved in [current folder]/Sox9/Sox9_[original name.tif].");
	
	Dialog.addString("Channels", "12");
	Dialog.addMessage("Channel(s) to extract. By default, channels 1 and 2 will be extracted.");
	
	Dialog.addRadioButtonGroup("Directory Options", newArray("Individual", "Batch"), 1, 2, "Batch")
	Dialog.addMessage("Individual deals with the current active image.\nFor batch, choose a folder containing the images.");
	
	Dialog.addRadioButtonGroup("2x scale", newArray("Yes", "No"), 1, 2, "No");
	Dialog.addMessage("Scale width and height up by 2x. Helps with segmentation.");

	Dialog.addMessage("Max Z Projection Configuration\nFor no projection, put 0 in both boxes.")
	Dialog.addNumber("Start: ", 0);
	Dialog.addToSameRow();
	Dialog.addNumber("End: ", 0);

	Dialog.show();

	setname = Dialog.getString();
	setchan = Dialog.getString();

	if (Dialog.getRadioButton() == "Batch") {
		batch = true;
	} else {
		batch = false;
	}

	if (Dialog.getRadioButton() == "Yes") {
		scale = true;
	} else {
		scale = false;
	}

	zstart = Dialog.getNumber();
	zend   = Dialog.getNumber();

	if (zstart == 0 || zend == 0) {
		maxproj = false;
	} else {
		maxproj = true;
	}
}

function build_arg() {
	setarray = newArray(numchan);
	for (i=0; i<numchan; i++) {
		setarray[i] = substring(setchan,i,i+1);
	}
	
	arg = "";
	for (i=1; i<=numchan; i++) {
		arg = arg + " c" + i + "=" + "C" + setarray[i-1] + "-temp";
	}
	return arg + " create";
}

function process() {
	getDimensions(width, height, channels, slices, frames);
	if (slices != 1 && maxproj == true) {
		run("Z Project...", "start=" + zstart + " stop=" + zend + " projection=[Max Intensity]");
	}

	rename("temp");
	run("Split Channels");
	
	if (numchan > 1) {
		run("Merge Channels...", arg);
	} else {
		selectWindow("C" + setchan + "-temp");
	}
	if (scale) {
		run("Size...", "width=" + width*2 + " height=" + height*2 + " constrain average interpolation=Bilinear");
	}
}
