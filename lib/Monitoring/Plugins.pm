#!/usr/bin/false

package Monitoring::Plugins;

use strict;
use warnings;

use Module::Pluggable
    search_path => ['Monitoring::Plugins'],
    except      => qr/^Monitoring::Plugins::.+::/, #limit to 1 level.
    require     => 1,
    sub_name    => 'modules';

sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    
    my %hash = (
        'modules' => undef,
    );
    
    my $self = bless( \%hash, $class );
    $self->loadModules();
    
    return $self;
}
    
sub loadModules {
    my $self = shift;
    
    # First clear any pluggable modules from %INC so they are reloaded.
    if ( $self->{'modules'} ) {
        for my $module ( keys %{ $self->{'modules'} } ) {
            my $incmod = $self->{'modules'}->{$module}.'.pm';
            $incmod =~ s|::|/|g;
            
            if ( $INC{ $incmod } ) {
                delete $INC{ $incmod }
            }
        }
    }

    #Stash the available pluggins in %modules, then to the object.
    my %modules = map {
        my $mod = $_;
        $mod =~ s/^Monitoring::Plugins:://;
        $mod => $_
    } $self->modules();
    
    $self->{'modules'} = \%modules;

    return 1;
}

sub register {
    my $self = shift;
    my @registrations;
    
    for my $mod ( $self->modules() ) {
        my @regs;

        eval {
            @regs = $mod->register();
        };
        unless ($@) {
          push @registrations, @regs;
        }
    }
    
    return wantarray ? @registrations : \@registrations;
}

sub discover {
    my $self   = shift;
    my $module = shift;
    
    my $result;

    if ( $self->{'modules'}->{$module} ) {
        eval {
            #Run the action method from the module
            $result = $self->{'modules'}->{$module}->discover();
        };
        if ($@) {
          $result = {};
        }
    }
    
    unless (    ref $result and ref $result eq 'HASH' 
            and $result->{'data'} and ref $result->{'data'} eq 'ARRAY' ){

       #this return is not valid.  it should be a hash ref with a 
       #data key wich is an array ref.
       
       #log an error
       
       #return a graceful {}
       $result = {};
    }
    
    #Validate the data.
    my @newData;
    ITEM:
    for my $item ( @{$result->{'data'}} ) {
        ATTR:
        for my $attr ( keys %{$item} ) {
            #log an error re invalid macro in return
            next ITEM unless $attr =~ /\{#[A-Z0-9]+\}/;
        }
        push @newData, $item;
    }
    $result->{'data'} = \@newData;

    return wantarray ? %{$result} : $result; 
}
        
sub test {
    my $self   = shift;
    my $module = shift;
    my @args   = @_;
    
    my $result = '';
    if ( $self->{'modules'}->{$module} ) {
        eval {
            #Run the action method from the module
            $result = $self->{'modules'}->{$module}->test(@args);
        };
        if ($@) {
            $result = '';
        }
    }
    
    return $result;
}

1;
