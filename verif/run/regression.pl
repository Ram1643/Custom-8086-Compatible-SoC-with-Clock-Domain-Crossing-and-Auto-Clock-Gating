#!/usr/bin/perl
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename;

# --- Hardcoded configurations ---
my $testlist_file = "regression.list";
my $orig_flist    = "../../rtl/rtl.flist";
my $local_flist   = "resolved_rtl.flist";

# ============================================================================
# PHASE 0: CLEANUP
# ============================================================================
print "Cleaning environment...\n";
system("rm -rf simv.vdb merged_coverage coverage_html_report *.log $local_flist simv csrc");

# ============================================================================
# PHASE 1: AUTOMATED PATH RESOLUTION (.flist)
# ============================================================================
print "Resolving RTL paths from $orig_flist...\n";

my $abs_flist_path = abs_path($orig_flist) 
    or die "[-] FATAL: Could not find $orig_flist. Please check the path.\n";
my $flist_dir = dirname($abs_flist_path);

open(my $in_fh, '<', $orig_flist) or die "[-] FATAL: Cannot open $orig_flist\n";
open(my $out_fh, '>', $local_flist) or die "[-] FATAL: Cannot create $local_flist\n";

while (my $line = <$in_fh>) {
    chomp $line;
    $line =~ s/^\s+|\s+$//g; # Trim leading/trailing whitespace
    
    next if ($line =~ /^#/ || $line eq ""); # Skip comments and empty lines

    if ($line =~ /^[-+]/ || $line =~ /^\// || $line =~ /^\$/) {
        # Keep compiler flags (+incdir+), absolute paths (/home/...), and env variables ($ENV) as-is
        print $out_fh "$line\n";
    } else {
        # Prepend the absolute directory to relative RTL paths
        print $out_fh "$flist_dir/$line\n";
    }
}
close($in_fh);
close($out_fh);
print "[+] Created fully resolved file list: $local_flist\n\n";

# ============================================================================
# PHASE 2: PARSE THE TESTLIST
# ============================================================================
my @test_queue;
my %current_test;

open(my $list_fh, '<', $testlist_file) or die "[-] FATAL: Cannot open $testlist_file\n";

while (my $line = <$list_fh>) {
    chomp $line;
    $line =~ s/^\s+|\s+$//g;
    next if ($line =~ /^#/ || $line eq "");

    if ($line eq "[TEST]") {
        push @test_queue, { %current_test } if keys %current_test;
        %current_test = ();
    } 
    elsif ($line =~ /^(name|location|parse_options|run_options)\s*=\s*(.*)$/) {
        $current_test{$1} = $2;
    }
}
push @test_queue, { %current_test } if keys %current_test; # Push the final test
close($list_fh);

print "Found " . scalar(@test_queue) . " tests in $testlist_file.\n\n";

# ============================================================================
# PHASE 3: SEQUENTIAL EXECUTION LOOP
# ============================================================================
foreach my $test (@test_queue) {
    my $name  = $test->{name};
    my $loc   = $test->{location};
    my $parse = $test->{parse_options};
    my $run   = $test->{run_options};

    print "==================================================================\n";
    print " RUNNING TEST: $name\n";
    print "==================================================================\n";

    # Step A: Compile the RTL using the auto-resolved local .flist
    my $compile_log = "${name}_compile.log";
    my $compile_cmd = "vcs $parse -f $local_flist ../tb/tb.sv  -l $compile_log";
    
    print "-> Compiling...\n";
    my $compile_status = system($compile_cmd);

    if ($compile_status != 0) {
        print "[-] ERROR: Compilation failed. Check '$compile_log'. Skipping to next test.\n\n";
        next;
    }

    # Step B: Stage the firmware file locally for the simulator
    print "-> Staging firmware...\n";
    system("cp $loc/*.hex ./ 2>/dev/null");
    
    # Step C: Simulate
    my $sim_log = "${name}_sim.log";
    my $run_cmd = "./simv $run -l $sim_log";
    
    print "-> Simulating...\n";
    my $run_status = system($run_cmd);

    if ($run_status != 0) {
        print "[-] ERROR: Simulation crashed or flagged an error. Check '$sim_log'.\n";
    } else {
        print "[+] SUCCESS: $name completed cleanly.\n";
    }
    print "\n";
}

# ============================================================================
# PHASE 4: MERGE COVERAGE
# ============================================================================
print "==================================================================\n";
print " MERGING COVERAGE METRICS\n";
print "==================================================================\n";

if (-d "simv.vdb") {
    system("urg -dir simv.vdb -dbname merged_coverage -report coverage_html_report");
    print "\n[+] Regression Complete!\n";
    print "    View results: firefox coverage_html_report/dashboard.html &\n";
} else {
    print "[-] ERROR: No coverage database (simv.vdb) found. Verify your -cm flags.\n";
}
