package Empire::ProductType;
# Empire ProductType object

use strict;
use warnings;
use Carp;

our %DEFAULT = ('^'=>{fullname=>'gold dust',
		      reqlevel=>0,
		      reso_depl=>1},
		'u'=>{fullname=>'radioactive materials',
		      reqlevel=>0,
		      reso_depl=>1},
		'p'=>{fullname=>'happy strollers',
		      reqlevel=>1,
		      reso_depl=>0},
		'd'=>{fullname=>'guns',
		      reqlevel=>0,
		      reso_depl=>0},
		'i'=>{fullname=>'shells',
		      reqlevel=>0,
		      reso_depl=>0},
		'm'=>{fullname=>'iron ore',
		      reqlevel=>0,
		      reso_depl=>1},
		'g'=>{fullname=>'gold dust',
		      reqlevel=>0,
		      reso_depl=>1},
		'a'=>{fullname=>'food',
		      reqlevel=>0,
		      reso_depl=>1},
		'o'=>{fullname=>'oil',
		      reqlevel=>0,
		      reso_depl=>1},
		'j'=>{fullname=>'light construction materials',
		      reqlevel=>0,
		      reso_depl=>0},
		'k'=>{fullname=>'heavy construction materials',
		      reqlevel=>0,
		      reso_depl=>0},
		't'=>{fullname=>'technological breakthroughs',
		      reqlevel=>1,
		      reso_depl=>0},
		'r'=>{fullname=>'medical discoveries',
		      reqlevel=>1,
		      reso_depl=>0},
		'l'=>{fullname=>'a class of graduates',
		      reqlevel=>1,
		      reso_depl=>0},
		'b'=>{fullname=>'gold bars',
		      reqlevel=>0,
		      reso_depl=>0},
		'%'=>{fullname=>'petrol',
		      reqlevel=>0,
		      reso_depl=>0},
	       );
our %CONSTANT = ('h'=>'V_HCM',
		 'l'=>'V_LCM',
		 'p'=>'V_PETROL',
		 'o'=>'V_OIL',
		 's'=>'V_SHELL',
		 'g'=>'V_GUN',
		 'i'=>'V_IRON',
		 'd'=>'V_DUST',
		 'f'=>'V_FOOD',
		 'b'=>'V_BAR',
		 'r'=>'V_RAD');
our %LEVEL = ('t'=>'NAT_TLEV',
	      'r'=>'NAT_RLEV',
	      'p'=>'NAT_PLEV',
	      'l'=>'NAT_ELEV');
our %RESOURCE = ('i'=>'sct_min',
		 'd'=>'sct_gmin',
		 'f'=>'sct_fertil',
		 'o'=>'sct_oil',
		 'r'=>'sct_uran',
		);
sub new {

    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    my $param = shift;

    $self = $DEFAULT{$param->{type}};
    bless $self,$class;
    for my $key (keys %{$param}) {
	if ($key eq 'reso_depl' && $self->{reso_depl} == 1) {
	    if ($param->{reso_depl} > 0) {
		$self->{reso_depl} = $param->{reso_depl};
	    }
	    else {
		$param->{reso_depl} = 0;
	    }
	}
	else {
	    $self->{$key} = $param->{$key};
	}
    }
    return $self;
}
sub write_code {

    my $self = shift;

    print  '{'.($#{$self->{use}}+1).', ';
    print  '{'.join(',',map($CONSTANT{$_->{pmnem}},@{$self->{use}})).'}';
}
1;
