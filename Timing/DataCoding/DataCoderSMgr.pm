package DataCoderSMgr;
#######################################
#
#   This package creates a Data Coder specific State Manager object 
#   Extends the methods in the base _smgr class
#
#######################################

#use Moo;
use Moose;
use DateTime;
use Scalar::Util::Reftype;

extends 'StateManager';

my $this_version = 0.200103;
my $publish_date = '2014.12.11';

has 'this_version' => (isa => 'Num', is => 'ro', default => 0.200103 );

## builder methods

## configuration methods


no Moose; # keywords are removed from the TSCourse package

1;  # so the require or use succeeds