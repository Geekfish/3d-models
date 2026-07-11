// Balcony door handle mounting plate

$fa = 2;
$fs = 0.4;

// ---- PARAMETERS (mm) ----
rail_width = 3;
rail_height = 0.4;

plate_length = 180; // long axis
plate_width_excl_rails = 27;
plate_width_total = plate_width_excl_rails + (rail_width * 2);
plate_height = 4.5;

screw_hole_diameter = 7.5;
screw_countersink_diameter = 11;
screw_countersink_depth = plate_height / 1.8;

keyhole_head_diameter = 17.5;
keyhole_head_radius = keyhole_head_diameter / 2;
keyhole_length_total = 33.6;
keyhole_slot_width = 10.3;
keyhole_slot_reach = keyhole_length_total - keyhole_head_radius;
keyhole_cap_radius = keyhole_slot_width / 2;

handle_width = 5;
handle_height = 10;
handle_rounding_radius = 1.4;

// Distances
// Each screw hole is the same distance from the top/bottom edge of the plate (20 mm)
// Screw holes and keyhole are slightly off-center, towards the right edge of the plate (as viewed from the bottom, rails visible)
dist_screw_hole_to_top = 20;
dist_screw_hole_to_empty_edge = 10.5;
dist_screw_hole_to_keyhole = 6.3;

offset_plate_holes_y = dist_screw_hole_to_empty_edge + screw_hole_diameter / 2;
offset_screw_holes_x = dist_screw_hole_to_top + screw_hole_diameter / 2;

eps = 0.01;

debug_rails = false;


module plate() {
    cube([plate_length, plate_width_total, plate_height]);
}


module round_all (n) {
    offset(r = +n) offset(delta = -n)
        // Fillet idiom: offset out, then back in
        offset(r = -n) offset(delta = +n)
            children();
}

module handle() {
    rotate([90, 0, 90])
    linear_extrude(height = plate_length) {
        round_all(handle_rounding_radius, $fn=40) {
            // Main Handle
            square([handle_width, handle_height]);
            
            // Top "bump"
            translate([-handle_width, handle_height - 2, 0])
                square([handle_width + 2, 2]);
            
            // Bottom foot (for fillet)
            translate([-4, -2.6, 0])
                square([handle_width+2, 4]);
        }
    }
}

module rail() {
    cube([plate_length, rail_width, rail_height + eps]);
}

module right_rail() {
    translate([0, plate_width_total - rail_width, -rail_height])
        rail();
}

module left_rail() {
    translate([0, 0, -rail_height])
        rail();
}

module screw_hole() {
    translate([0, 0, -eps])
        cylinder(d = screw_hole_diameter, h = plate_height + (eps * 2));
    translate([0, 0, plate_height - screw_countersink_depth])
        countersink();
}

module countersink() {
    cylinder(d1 = screw_hole_diameter, d2 = screw_countersink_diameter, h = screw_countersink_depth + eps * 2);
}

module top_screw_hole() {
    translate([offset_screw_holes_x, offset_plate_holes_y, 0])
        screw_hole();
}

module bottom_screw_hole() {
    translate([plate_length - offset_screw_holes_x, offset_plate_holes_y, 0])
        screw_hole();
}

module keyhole() {
    keyhole_x =
        plate_length
        - dist_screw_hole_to_top
        - screw_hole_diameter
        - keyhole_length_total
        - dist_screw_hole_to_keyhole
        + keyhole_head_radius;

    translate([keyhole_x, offset_plate_holes_y, -eps])
    linear_extrude(height = plate_height + (eps * 2)) {
        // Head
        circle(d = keyhole_head_diameter);
        // Slot
        translate([(keyhole_slot_reach - keyhole_cap_radius) / 2, 0, 0])
            square(size = [keyhole_slot_reach - keyhole_cap_radius, keyhole_slot_width], center = true);
        // Cap
        translate([keyhole_slot_reach - keyhole_cap_radius, 0, 0])
            circle(r = keyhole_cap_radius);
    }

}

module plate_holes() {
    top_screw_hole();
    bottom_screw_hole();
    keyhole();
}

difference() {
    union() {
        plate();
        translate([0, plate_width_total - handle_width, plate_height - eps - handle_rounding_radius])
            handle();
    }
    plate_holes();
}

left_rail();
right_rail();
