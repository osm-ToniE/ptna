package PtnaStrings;

use strict;

use POSIX;
use Locale::gettext qw();       # 'gettext()' will be overwritten in this file (at the end), so don't import from module into our name space

use utf8;
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

use Encode;                                                

use Exporter;
use base qw (Exporter);

our @EXPORT_OK  = qw( InitMessageStrings InitOptionStrings GetMessageKeys GetMessageValue GetOptionKeys GetOptionValue %MessageHash @MessageList %OptionHash @OptionList );


my %MessageHash = ();
my @MessageList = ();
my %OptionHash =  ();
my @OptionList =  ();


#############################################################################################
#
# 
#
#############################################################################################

sub InitMessageStrings {
    
    my $i = 0;

    $i++;
    $MessageList[$i]->{'message'}                = "'ref' is not set";
    $MessageList[$i]->{'option'}                 = "";
    $MessageList[$i]->{'description'}            = "";
    $MessageList[$i]->{'fix'}                    = "";
    $MessageList[$i]->{'image'}                  = "";
    $MessageHash{$MessageList[$i]->{'message'}}  = $i;
    
    return 0;
}


sub GetMessageKeys {
    return keys %MessageHash;
}


sub GetMessageValue {
    my $key     = shift;
    my $string  = shift;
    
    return $MessageList[$MessageHash{$key}]->{$string}    if ( $key && defined $MessageHash{$key} && $string && exists $MessageList[$MessageHash{$key}]->{$string} );
    return undef;
}
   

sub InitOptionStrings {
    
    my $i = 0;

    $i++;
    $OptionList[$i]->{'option'}                 = "--check-name";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;
    
    $i++;
    $OptionList[$i]->{'option'}                 = "--check-name-relaxed";
    $OptionList[$i]->{'default'}                = "OFF";
    $OptionList[$i]->{'description'}            = "";
    $OptionHash{$OptionList[$i]->{'option'}}    = $i;
    

    return 0;
}


sub GetOptionKeys {
    return keys %OptionHash;
}


sub GetOptionValue {
    my $key     = shift;
    my $string  = shift;
    
    return $OptionList[$OptionHash{$key}]->{$string}    if ( $key && defined $OptionHash{$key} && $string && exists $OptionList[$OptionHash{$key}]->{$string} );
    return undef;
}
   

#############################################################################################
#
# overwrite Locale::gettext::gettext() by our own function which simply decodes the getrieved data
#
#############################################################################################

sub gettext {
    return decode( 'utf8', Locale::gettext::gettext( @_ ) );
}


#############################################################################################
#
# overwrite Locale::gettext::ngettext() by our own function which simply decodes the getrieved data
#
#############################################################################################

sub ngettext {
    return decode( 'utf8', Locale::gettext::ngettext( @_ ) );
}



1;
