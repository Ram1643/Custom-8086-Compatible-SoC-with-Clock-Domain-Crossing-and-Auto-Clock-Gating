#!/usr/bin/perl
use strict;
use warnings;

my $infile = $ARGV[0] or die "Usage: perl assembler.pl <input.asm>\n";
my $outfile = "firmware1.hex";

open(my $in, '<', $infile) or die "Cannot open $infile: $!\n";
open(my $out, '>', $outfile) or die "Cannot open $outfile: $!\n";

print "Assembling $infile...\n";

my @hex_memory = ();

while (my $line = <$in>) {
    # ==========================================
    # 1. SANITIZATION
    # ==========================================
    $line =~ s/;.+//;          
    $line =~ s/^\s+|\s+$//g;   
    next if $line eq '';       

    # ==========================================
    # 2. MACROS
    # ==========================================
    if ($line =~ /^TIMES\s+(\d+)\s+NOP$/i) {
        my $count = $1;
        for (my $i = 0; $i < $count; $i++) {
            push @hex_memory, "90";
        }
        next; 
    }

    # ==========================================
    # 3. COMPLETE OPCODE DICTIONARY
    # ==========================================
    
    # --- Register Loads (Immediate 16-bit) ---
    elsif ($line =~ /^MOV\s+AX,\s*([0-9A-Fa-f]{4})$/i) {
        push @hex_memory, "B8", substr($1, 2, 2), substr($1, 0, 2);
    }
    elsif ($line =~ /^MOV\s+BX,\s*([0-9A-Fa-f]{4})$/i) {
        push @hex_memory, "BB", substr($1, 2, 2), substr($1, 0, 2);
    }
    elsif ($line =~ /^MOV\s+CX,\s*([0-9A-Fa-f]{4})$/i) {
        push @hex_memory, "B9", substr($1, 2, 2), substr($1, 0, 2);
    }
    elsif ($line =~ /^MOV\s+SI,\s*([0-9A-Fa-f]{4})$/i) {
        push @hex_memory, "BE", substr($1, 2, 2), substr($1, 0, 2);
    }
    elsif ($line =~ /^MOV\s+DI,\s*([0-9A-Fa-f]{4})$/i) {
        push @hex_memory, "BF", substr($1, 2, 2), substr($1, 0, 2);
    }

    # --- System Control ---
    elsif ($line =~ /^MOV\s+CR0,\s*AX$/i) {
        push @hex_memory, "0F";
    }

    # --- Memory-Mapped I/O ---
    elsif ($line =~ /^MOV\s+\[([0-9A-Fa-f]{4})\],\s*AX$/i) {
        push @hex_memory, "A3", substr($1, 2, 2), substr($1, 0, 2);
    }
    elsif ($line =~ /^MOV\s+AX,\s*\[([0-9A-Fa-f]{4})\]$/i) {
        push @hex_memory, "A1", substr($1, 2, 2), substr($1, 0, 2);
    }

    # --- Arithmetic ---
    elsif ($line =~ /^ADD\s+AX,\s*BX$/i) {
        push @hex_memory, "01", "D8"; # Opcode 01, ModRM D8
    }

    # --- Interrupts & Hardware Triggers ---
    elsif ($line =~ /^STI$/i) { push @hex_memory, "FB"; }
    elsif ($line =~ /^CLI$/i) { push @hex_memory, "FA"; }
    elsif ($line =~ /^IRET$/i) { push @hex_memory, "CF"; }
    
    elsif ($line =~ /^TRIG_IP1$/i) { push @hex_memory, "E1"; }
    elsif ($line =~ /^TRIG_IP2$/i) { push @hex_memory, "E2"; }
    elsif ($line =~ /^TRIG_IP3$/i) { push @hex_memory, "E3"; }
    
    # --- CPU States ---
    elsif ($line =~ /^HLT$/i) { push @hex_memory, "F4"; }
    elsif ($line =~ /^NOP$/i) { push @hex_memory, "90"; }
    
    # ==========================================
    # 4. DIRECTIVES
    # ==========================================
    elsif ($line =~ /^\.ORG\s+([0-9A-Fa-f]{4})$/i) {
        my $target_byte_addr = hex($1) * 2; 
        my $current_byte_addr = scalar(@hex_memory);
        
        if ($target_byte_addr < $current_byte_addr) {
            die "Error: .ORG address 0x$1 is behind current position!\n";
        }
        
        while (scalar(@hex_memory) < $target_byte_addr) {
            push @hex_memory, "90";
        }
    }
    
   # JUMPING INSTRUCTIONS:
    
     # --- Branching & Logic ---
    elsif ($line =~ /^CMP\s+AX,\s*([0-9A-Fa-f]{4})$/i) {
        push @hex_memory, "3D", substr($1, 2, 2), substr($1, 0, 2);
    }
    elsif ($line =~ /^JE\s+([0-9A-Fa-f]{4})$/i) {
        my $target_byte = hex($1) * 2; # Convert Word address to Byte address for hardware
        my $hex_addr = sprintf("%04X", $target_byte);
        push @hex_memory, "74", substr($hex_addr, 2, 2), substr($hex_addr, 0, 2);
    }
    elsif ($line =~ /^JMP\s+([0-9A-Fa-f]{4})$/i) {
        my $target_byte = hex($1) * 2; # Convert Word address to Byte address for hardware
        my $hex_addr = sprintf("%04X", $target_byte);
        push @hex_memory, "E9", substr($hex_addr, 2, 2), substr($hex_addr, 0, 2);
    } 
    else {
        die "Syntax Error: Unrecognized instruction -> '$line'\n";
    }
}

# ==========================================
# 5. WRITE FIRMWARE.HEX (16-bit Word Aligned)
# ==========================================
for (my $i = 0; $i < scalar(@hex_memory); $i += 2) {
    my $low_byte = $hex_memory[$i];
    my $high_byte = ($i + 1 < scalar(@hex_memory)) ? $hex_memory[$i+1] : "00";
    print $out "$high_byte$low_byte\n";
}

print "Done! Output saved to $outfile\n";
close($in);
close($out);


