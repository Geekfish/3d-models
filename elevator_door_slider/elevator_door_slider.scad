// Elevator door slider/hinge replacement part.
//
// Print in PETG or stronger material.
// It is a sliding fitting under sustained load.
print_on_end = true;

// Preview only
debug_relief = false;


// ---- PARAMETERS (mm) ----
$fa = 2;
$fs = 0.4;

eps = 0.01;

// ---- MEASURED (mm) ----
block_length   = 45.1;
block_width    = 22.8;   // measured 22.76, rounded
block_height   = 12.8;

leg_thickness  = 2.6;    // each side
web_at_land    = 9.5;    // channel ceiling to top face, at the bearing lands
boss_outer_d   = 15.6;
insert_outer_d = 10.0;   // measured off the heat-set insert in hand, at the serrated end.
insert_nose_d  = 9.0;    // same insert, plain end. It is tapered, so it has two.
insert_length  = 12.0;
rib_width      = 3.16;
relief_length  = 25.46;
relief_depth   = 2.6;    // how much deeper the middle pocket sits
screw_length   = 12;     // M8 x 1, fine pitch (coarse M8 would be 1.25)

channel_clearance = 0;
channel_lead_in   = 1;   // Radius of the rounded lead-in at each end of the channel
lead_in_steps     = 16;  // Slices the rounded lead-in is swept from. More is smoother
insert_chamfer    = 0.5;

// ---- CALCULATED (mm) ----
channel_width         = block_width - 2 * leg_thickness;
channel_depth_at_land = block_height - web_at_land;
web_at_relief         = web_at_land - relief_depth;
channel_depth_relief  = channel_depth_at_land + relief_depth;
fitted_channel_width  = channel_width + channel_clearance;
relief_pocket_depth   = channel_depth_relief;
insert_bore_d         = insert_nose_d;

function block_width_for(chan_w) = chan_w + (leg_thickness * 2);

fitted_block_width = block_width_for(fitted_channel_width);

boss_x = block_length / 2;
boss_y = fitted_block_width / 2;
boss_r = boss_outer_d / 2;

boss_height = screw_length - web_at_relief;
boss_top = block_height + boss_height;
bore_length = boss_top - relief_pocket_depth;


module channel(length, chan_w) {
    translate([-eps, leg_thickness, -eps])
        cube([length + (eps * 2), chan_w, channel_depth_at_land + eps]);
}


module lead_in_slice(chan_w, x) {
    u = min(channel_lead_in, channel_lead_in - x);
    f = channel_lead_in - sqrt(pow(channel_lead_in, 2) - pow(u, 2));

    translate([x, leg_thickness - f, -eps])
        cube([eps, chan_w + (f * 2), channel_depth_at_land + f + eps]);
}

module lead_in(chan_w) {
    step = channel_lead_in / lead_in_steps;

    for (i = [0 : lead_in_steps - 1])
        hull() {
            lead_in_slice(chan_w, i * step);
            lead_in_slice(chan_w, (i + 1) * step);
        }

    // A hair proud of the end face, so the cut definitely breaks through.
    hull() {
        lead_in_slice(chan_w, -eps);
        lead_in_slice(chan_w, 0);
    }
}


module lead_ins(length, chan_w) {
    lead_in(chan_w);

    translate([length, 0, 0])
        mirror([1, 0, 0])
            lead_in(chan_w);
}


// Block with the channel and both lead-ins taken out.
module shoe_body(length, chan_w = fitted_channel_width) {
    difference() {
        cube([length, block_width_for(chan_w), block_height]);

        channel(length, chan_w);
        lead_ins(length, chan_w);
    }
}


// Centred along the length, full channel width. NOT wider than the channel: the
// bump rides on the track and the track fits the channel, so the bump cannot be
// wider than the channel -- widening past that would only undercut the legs.
module relief_pocket(length, pocket_length, pocket_depth, chan_w = fitted_channel_width) {
    translate([(length - pocket_length) / 2, leg_thickness, -eps])
        cube([pocket_length, chan_w, pocket_depth + eps]);
}


module block() {
    shoe_body(block_length);
}


// A gusset supporting the boss
module rib() {
    translate([0, (fitted_block_width + rib_width) / 2, block_height - eps])
        rotate([90, 0, 0])
            linear_extrude(height = rib_width)
                polygon([[0, 0],
                         [block_length, 0],
                         [boss_x + boss_r, boss_height],
                         [boss_x - boss_r, boss_height]]);
}


module boss() {
    translate([boss_x, boss_y, block_height - eps])
        cylinder(d = boss_outer_d, h = boss_height + eps);
}


// Cosmetic-ish
// It is what lets the head finish flush when there is no spare depth to sink into.
module bore() {
    translate([boss_x, boss_y, -eps])
        cylinder(d = insert_bore_d, h = boss_top + (eps * 2));

    translate([boss_x, boss_y, boss_top - insert_chamfer])
        cylinder(d1 = insert_bore_d,
                 d2 = insert_bore_d + (insert_chamfer * 2),
                 h = insert_chamfer + eps);
}


module pocket() {
    relief_pocket(block_length, relief_length, relief_pocket_depth);
}


module slider() {
    difference() {
        union() {
            block();
            rib();
            boss();
        }

        pocket();
        bore();
    }
}


// ---- CHECKS ----
echo(str("channel       ", channel_width, " + ", channel_clearance, " = ", fitted_channel_width, " wide"));
echo(str("outer width   ", block_width, " -> ", fitted_block_width, ", legs stay ", leg_thickness));
echo(str("pocket        ", relief_length, " long x ", relief_pocket_depth, " deep"));
echo(str("web at relief ", block_height - relief_pocket_depth));
echo(str("bore          ", bore_length, " long, screw is ", screw_length));

// The insert is full depth, so anything that shortens the bore leaves insert or
// screw protruding into the pocket, where the bump is.
assert(bore_length >= insert_length - eps,
       "bore is shorter than the insert -- the insert will protrude into the relief pocket");
assert(bore_length >= screw_length - eps,
       "bore is shorter than the screw -- the screw will protrude into the relief pocket");

module assembly() {
    slider();

    if (debug_relief)
        color("mediumorchid", 0.6)
            pocket();
}

rotate(print_on_end ? [0, -90, 0] : [0, 0, 0])
    assembly();
