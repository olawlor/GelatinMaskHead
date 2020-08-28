/*
Human head with rubbery castable face and anatomical underlying skull.
Designed for COVID prevention mask testing.

Explanation of this file and initial testing results:
https://docs.google.com/document/d/1Q9jaSaZRyKj-hi1BDpFaLHJNcuCx2OrSKFoyBqVJWUo/edit#

Rev 2, with:
	- Face overmold points the opposite direction, so it's hairy on non-cast side.

Dr. Orion Lawlor, lawlor@alaska.edu, updated 2020-06-23

Source files needed:
"Human_Skull_Scan_fixed2" is CC-A-NC modified from:
    https://www.thingiverse.com/thing:2368585

"8-NIOSH-Medium" is from the standard NIOSH mask testing head model,
size "medium", from the "fit2face challenge" data packet:
    https://www.americamakes.us/fit2face/

*/

inch=25.4;


// Skull, scaled to real size and lined up with head
module skull() {
	rotate([0,0,90-3])
	rotate([5,0.5,1])
	translate([-5.5,-10,35])
	scale([1.05,1.05,1.05])
	import("./Human_Skull_Scan_fixed2.stl",convexity=8);
}

// Spacers to take up space of eyes and tongue in skull
module skull_spacers() {
	
	// Tongue area spacer
	hull() {
		// Smaller front sphere
		translate([80,0,65])
			scale([1,0.8,1])
				sphere(d=75);
		// Larger back sphere
		translate([40,0,75])
			scale([1,1,1])
				sphere(d=95);
	}
	
	// Eyeballs, extra-large for mold indexing
	ipd=62; // inter-pupillary distance
	for (side=[-1,+1])
	translate([66,ipd/2*side,130])
		sphere(d=36);
}


// Fix orientation of head to standard printable
module niosh_to_standard() {
	translate([10,0,90])
	rotate([0,-25,0])
	rotate([0,90,0])
	rotate([0,0,90])
	 children();
}

module niosh_inside() {
	niosh_to_standard()
		import("./8-NIOSH_medium_interior.stl",convexity=2);
}
module niosh_outside() {
	niosh_to_standard()
		import("./8-NIOSH_medium_20k.stl",convexity=6);
}

// Skull, trimmed by niosh outer surface
module skull_trimmed() {
	intersection() {
		skull();
		translate([-1,0,0])
			niosh_outside();
	}
}

module niosh(cutaway=0) {
	difference() {
		niosh_outside();
		niosh_inside();
		
		if (cutaway) cube([1000,1000,1000]);
	}
}

// Lawlor head, for comparison (bolts, clearance, etc)
//module lawlor_head() {
//	import("../head_vase.stl");
//}

// Illustrates head with skull inside
module illustration(cutaway=0) {
	union() {
		skull_trimmed();
		#niosh(cutaway);
		// #lawlor_head();
	}
}


// X coordinate of start of face (back side)
face_casting_start_x=50;
face_casting_center_z=80;

nose_air_tube_z=150;

face_mounting_bolt_z=50;

// Forward area of face for casting
module face_casting_zone(inset=0) {
	hull() 
	for (diagonal_chin=[0,40])
	for (diagonal_eyes=[0,40])
	{
	translate(
		[face_casting_start_x+diagonal_chin+diagonal_eyes+1000,
		 0,
		 face_casting_center_z-diagonal_chin+diagonal_eyes]
		) 
		cube([2000-2*inset,2000-2*inset,80-2*inset],center=true);
	}
}



// Cast-in copper tubing (nose air inlet)
breathing_start=[75,0,145];
breathing_rotate=[0,-45,0];
airtube_OD=3/8*inch;
airtube_long=80;
module nose_air_tube(fatten=0,upshift=0) {
	
	for (nose0mouth1=[0,1]) {
	translate(breathing_start)
	//translate([face_casting_start_x,0,nose_air_tube_z])
	rotate(breathing_rotate)
		translate([nose0mouth1*-30,0,upshift])
		cylinder(d=airtube_OD+2*fatten,h=airtube_long-2*fatten,center=true,$fs=0.1,$fa=2);
	}
}

// Each individual nostril uses one of these tubes
nostril_flareout=[25,10,0]; // rotation per nostril
nostril_len=25;
module nostril_tube(clearance=0.0) {
	difference() {
		rotate([180,0,0])
		rotate(nostril_flareout)
			rotate([0,0,20])
			scale([1,0.7,1])
				cylinder($fs=0.1,$fa=2,d=airtube_OD+2*clearance,h=2*nostril_len,center=true);
		
		// Put in bilateral symmetry plane
		translate([0,-1000,0]) cube([2000,2000,2000],center=true);
		// Put in flared copper tubing
	}
}
// put nostril tube flat along Z axis again
module nostril_tube_undo() {
	translate([0,0,nostril_len])
	rotate([180,0,0])
	rotate(-nostril_flareout)
	rotate([180,0,0])
		children();
}

// Nostril holes are loose pieces cast into the face
module nostril_holes(clearance=0.0) {
	#for (side=[-1,+1]) scale([1,side,1])
	{
		translate(breathing_start)
		rotate(breathing_rotate)
		translate([0,0,-airtube_long/2])
			nostril_tube(clearance);
	}
}

// Mounting hole to bolt skull to head.
//  Tapped into plastic of skull
//  Goes clear through back of head, to allow tool to be inserted
module skull_mount_hole(clearance=0.2) {
	translate([face_casting_start_x+20,0,90])
		rotate([0,-90,0])
			cylinder(d1=0.25*inch+clearance,d2=12,h=180);
}

// Head non-printable areas
module head_holes(inset=0) {

	// Below head is nonprintable
	translate([0,0,inset-1000]) cube([2000,2000,2000],center=true);
	
	// Face area is printed separately (minus sign so back wall is solid)
	face_casting_zone(-inset);
	
	// Top access, also prevents overhang issues inside
	base=100; // start diameter of flared opening
	height=300; // height of flared area
	translate([-20,0,125+0.01*inset])
		cylinder(d1=base-2*inset,d2=base+2*height-2*inset,h=height);
}

// Main opening and mounting holes in bottom
module mounting_holes() {
	translate([45,0,-1]) linear_extrude(height=10) {
		circle(d=60);
		nbolts=6;
		for (angle=[120:360/nbolts:300-1])
			rotate([0,0,angle]) translate([40,0,0])
				circle(d=6);
	}
}

// Holes for pouring in castable face material
module face_fill_holes(inset=0) {
	for (side=[-1,+1]) scale([1,side,1])
		translate([55,50,115])
			rotate([0,-60,0])
			rotate([10,0,0])
				cylinder(d1=8+2*inset,
					d2=20+2*inset,
					h=25-inset);
}



// Head with hole for face
wall=3;
module head_without_face() {
	difference() {
		// Start with the exterior
		difference() {
			niosh_outside();
			head_holes();
		}
		
		// Clear out the interior
		difference() {
			niosh_inside();
			head_holes(wall);
			nose_air_tube(wall);
			face_fill_holes(wall);
		}
		
		// Final holes
		nose_air_tube();
		face_fill_holes();
		mounting_holes();
		skull_mount_hole();
		
		// Cutaway (illustration)
		// cube([200,100,200]);
	}
}

// Castable face (for volume estimate)
module face_castable() {
	difference() {
		intersection() {
			niosh_outside();
			face_casting_zone();
		}
		
		skull_trimmed();
		skull_spacers();
		nostril_holes();
	}
}

// Bones in face
module face_bones() {
	difference() {
		intersection() {
			union() {
				skull_trimmed();
				skull_spacers();
			}
			face_casting_zone(0.1);
		}
		
		nose_air_tube();
		skull_mount_hole(-1.5);
	}
}
// Back lying flat on build plate
module face_bones_printable() {
	translate([-80,0,0])
	rotate([0,-90,0])
	translate([-face_casting_start_x-0.1,0,0])
		face_bones();
}

// Outside casting block for face:
//   holds the castable face material in place.
casting_block_xlo=35;
casting_block_zlo=-wall;
casting_block_zhi=180;

module make_shear(p) {
   multmatrix([
		[1,0,p,0],
		[0,1,p,0],
		[0,0,1,0]
	  ]) children();
}

module casting_block_size() {
	translate([casting_block_xlo,-100,casting_block_zlo])
		//make_shear(-0.1)
			cube([100,200,casting_block_zhi-casting_block_zlo]);
}

// Outside of NIOSH head, enlarged slightly
module niosh_outside_enlarged() {
	for (xdel=[0,40])
	for (zdel=[0,50]) {
		scale_center=[20+xdel,0,80+zdel];
		s=1+2*wall/70;
		translate(+scale_center)
		scale([s,s,s])
		translate(-scale_center)
		{
			niosh_outside();
			skull_spacers();
		}
	}
}

// Lies flat and hold the liquid as the face is cast.
//  Removed from the final print.
module overmold() {
	// Flat base (and neck closure)
	bottom_x=75;
	translate([casting_block_xlo+bottom_x/2,0,casting_block_zlo+wall/2])
		cube([bottom_x,120,wall],center=true);
	
	// Flat top (and top closure)
	top_x=50;
	difference() {
		translate([casting_block_xlo+top_x/2,0,casting_block_zhi-wall/2])
			cube([top_x,110,wall],center=true);
		
		// Let air tube clear top plate
		nose_air_tube(wall,20);
	}
	
	difference() {
		intersection() {
			union() {
				// outer face surface
				niosh_outside_enlarged();
				
				// Extra meat around nostrils, so no leaks
				translate([115,0,110])
					sphere(d=37);
				
				// support to let us sit face-down
				for (sup=[-1,0,+1])
					translate([0,sup*40,0])
						cube([1000,wall/2,1000],center=true);
				
			}
			casting_block_size();
		}
		
		// Clearance inside for actual face
		niosh_outside();
		skull_spacers();
		nostril_holes(0.2);
		
		// Cutaway (illustration / debugging)
		//translate([100,10,0]) cube([1000,1000,1000]);
	}
	
}

module nostril_tubes_printable() {
		for(side=[-1,1]) scale([side,1,1])
			translate([40,0,0])
				nostril_tube_undo() nostril_tube();
	
}
module overmold_printable() {
	translate([-100,225,wall]) rotate([0,0,270])
	{
		overmold();
		translate([0,0,-wall]) rotate([0,0,90]) nostril_tubes_printable();
	}
}


bone_color=[0.7,0.9,0.9];
module one_plate_printable() {
	head_without_face();
	
	casting_block_printable();
	color(bone_color) face_bones_printable();
}

module demo_head() {
	//#face_castable();
	//head_without_face();
	
	color(bone_color) face_bones();
	
	#nostril_holes();
	#nose_air_tube();
	//#casting_block();
}

// demo_head();
// one_plate_printable();

head_without_face();
overmold_printable();
face_bones_printable();
// #face_castable();

// nostril_tubes_printable();
