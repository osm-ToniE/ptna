package OSM::Data;

use strict;

use Exporter;
use base qw (Exporter);

our %META       = ();       # store META information, if available
our %NODES      = ();       # store NODES via ID
our %WAYS       = ();       # store WAYS via ID
our %RELATIONS  = ();       # store RELATIONS via ID

our @EXPORT_OK  = qw( %META %NODES %WAYS %RELATIONS );

1;
