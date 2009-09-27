package ZConf::Weather;

use Weather::Underground;
use Text::NeatTemplate;
use ZConf;
use warnings;
use strict;

=head1 NAME

ZConf::Weather - A ZConf module for fetching weather information.

=head1 VERSION

Version 0.1.1

=cut

our $VERSION = '0.1.1';

=head1 SYNOPSIS

    use ZConf::Weather;

    my $zcw = ZConf::Weather->new();
    ...

=head1 FUNCTIONS

=head2 new

This initializes it.

One arguement is taken and that is a hash value.

=head3 hash values

=head2 autoinit

If this is set to true, it will automatically call
init the set and config. If this is set to false or
not defined, besure to check '$zcw->{init}' to see
if the config/module has been initiated or not.

If it is not specified, it will default to true.

=head2 set

This is the set to load initially.

=head4 zconf

If this key is defined, this hash will be passed to ZConf->new().

    my $zcw=ZConf::Weather->new();
    if($zcw->{error}){
        print "Error!\n";
    }

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	my $self={error=>undef, errorString=>undef};
	bless $self;

	#this sets the set to undef if it is not defined
	if (!defined($args{set})) {
		$self->{set}=undef;
	}else {
		$self->{set}=$args{set};
	}

	#this sets the set to 1 if it is not defined
	if (!defined($args{autoinit})) {
		$self->{autoinit}=1;
	}else {
		$self->{autoinit}=$args{set};
	}

	#this is done to keep from throwing an error when we try to pass it to ZConf->new
	if (!defined($args{zconf})) {
		$args{zconf}={};
	}

	#creates the ZConf object
	$self->{zconf}=ZConf->new(%{$args{zconf}});
	if(defined($self->{zconf}->{error})){
		warn("ZConf-Weather new:1: Could not initiate ZConf. It failed with '"
			 .$self->{zconf}->{error}."', '".$self->{zconf}->{errorString}."'");
		$self->{error}=1;
		$self->{errorString}="Could not initiate ZConf. It failed with '"
		                      .$self->{zconf}->{error}."', '".
							  $self->{zconf}->{errorString}."'";
		return $self;
	}


	#create the config if it does not exist
	#if it does exist, make sure the set we are using exists
    $self->{init} = $self->{zconf}->configExists("weather");
	if($self->{zconf}->{error}){
		warn("ZConf-Weather new:2: Could not check if the config 'weather' exists.".
			 " It failed with '".$self->{zconf}->{error}."', '"
			 .$self->{zconf}->{errorString}."'");
		$self->{error}=2;
		$self->{errorString}="Could not check if the config 'weather' exists.".
	   		                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
		return $self;
	}

	#if it is not inited, check to see if it needs to do so
	if ((!$self->{init}) && $self->{autoinit}) {
		$self->init($self->{set});
		if ($self->{error}) {
			warn('ZConf-Weather new:4: Autoinit failed.');
		}else {
			#if init works, it is now inited and thus we set it to one
			$self->{init}=1;
		}
		#we don't set any error stuff here even if the above action failed...
		#it will have been set any ways by init methode
		return $self;
	}

	#checks it is set to use the default set
	#use defined as '0' is a legit set name and is a perl boolean for false
	if ((!defined($self->{set})) && $self->{init}) {
		$self->{init}=$self->{zconf}->defaultSetExists('weather');
		if($self->{zconf}->{error}){
			warn("ZConf-Weather new:2: defaultSetExists failed for 'weather'.".
				 " It failed with '".$self->{zconf}->{error}."', '"
				 .$self->{zconf}->{errorString}."'");
			$self->{error}=2;
			$self->{errorString}="defaultSetExists failed for 'weather'.".
	   		                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
			return $self;
		}
	}

	#check it if it set to use a specific set
	#use defined as '0' is a legit set name and is a perl boolean for false
	if (defined($self->{set})) {
		$self->{init}=$self->{zconf}->setExists('weather', $self->{set});
		if($self->{zconf}->{error}){
			warn("ZConf-Weather new:2: defaultSetExists failed for 'weather'.".
				 " It failed with '".$self->{zconf}->{error}."', '"
				 .$self->{zconf}->{errorString}."'");
			$self->{error}=2;
			$self->{errorString}="defaultSetExists failed for 'weather'.".
	   		                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
			return $self;
		}
	}

	#the first one does this if the config has not been done yet
	#this one does it if the set has not been done yet
	#if it is not inited, check to see if it needs to do so
	if (!$self->{init} && $self->{autoinit}) {
		$self->init($self->{set});
		if ($self->{error}) {
			warn('ZConf-Weather new:4: Autoinit failed.');
		}else {
			#if init works, it is now inited and thus we set it to one
			$self->{init}=1;
		}
		#we don't set any error stuff here even if the above action failed...
		#it will have been set any ways by init methode
		return $self;
	}

	#reads it if it does not need to be initiated
	if ($self->{init}) {
		$self->{zconf}->read({set=>$self->{set}, config=>'weather'});
	}

	return $self;
}

=head2 getDefaultLocal

This gets what the default local is set to.

    my $local=$zcw->getDefaultLocal;
    if($zcw->{error}){
        print "Error!\n";
    }

=cut

sub getDefaultLocal{
	my $self=$_[0];

	$self->errorblank;

	if (!defined($self->{zconf}->{conf}{weather}{defaultLocal})) {
		warn('ZConf-Weather getDefaultLocal:15: No default local specified');
		$self->{error}=15;
		$self->{errorString}='No default local specified.';
		return undef;
	}

	return $self->{zconf}->{conf}{weather}{defaultLocal};
}

=head2 getDefaultType

This gets what the default type is set to.

    my $local=$zcw->getDefaultType;
    if($zcw->{error}){
        print "Error!\n";
    }

=cut

sub getDefaultType{
	my $self=$_[0];

	$self->errorblank;

	if (!defined($self->{zconf}->{conf}{weather}{defaultType})) {
		warn('ZConf-Weather getDefaultType:15: No default type specified');
		$self->{error}=15;
		$self->{errorString}='No default type specified.';
		return undef;
	}

	return $self->{zconf}->{conf}{weather}{defaultLocal};
}

=head2 getSet

This gets what the current set is.

    my $set=$zcw->getSet;
    if($zbm->{error}){
        print "Error!\n";
    }

=cut

sub getSet{
	my $self=$_[0];

	my $set=$self->{zconf}->getSet('weather');
	if($self->{zconf}->{error}){
		warn('ZConf-Weather getSet:2: ZConf error getting the loaded set the config "weather".'.
			 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			 'ZConf error string="'.$self->{zconf}->{errorString}.'"');
		$self->{error}=2;
		$self->{errorString}='ZConf error getting the loaded set the config "weather".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		return undef;
	}

	return $set;
}

=head2 getTemplate

This returns a template as a string.

    my $template=$zcw->getTemplate('some/template');
    if ($zcw->{error}) {
        print "Error!\n";
    }

=cut

sub getTemplate{
	my $self=$_[0];
	my $template=$_[1];

	$self->errorblank;

	if (!defined($template)) {
		warn('ZConf-Weather getTemplate:6: No template specified');
		$self->{error}=6;
		$self->{errorstring}='No template specified.';
		return undef;
	}

	my $returned=$self->templateExists($template);
	if ($self->{error}) {
		warn('ZConf-Weather getTemplate: templateExists errored');
		return undef;
	}

	if (!$returned) {
		warn('ZConf-Weather getTemplate:7: The template, "'.$template.'", does not exist');
		$self->{errror}=7;
		$self->{errorstring}='The template, "'.$template.'", does not exist';
		return undef;
	}

	return $self->{zconf}{conf}{weather}{'templates/'.$template};
}

=head2 getWeather

Returns the arrayref from Weather::Underground->get_weather.

The only arguement required is the name of the local.

    $aref=$zcw->getWeather('someLocal');
    if($zcw->{error}){
        print "Error!\n";
    }

=cut

sub getWeather{
	my $self=$_[0];
	my $name=$_[1];

	$self->errorblank;

	#inits the weather object...
	my $weather=$self->getWeatherObj($name);

	#gets the weather
	my $arrayref = $weather->get_weather();
	if (!$arrayref) {
		$self->{error}=12;
		$self->{errorString}='Failed to fetch the weather';
		warn('ZConf-Weather getWeather:12: '.$self->{errorString});
		return undef;
	}

	return $arrayref;
}

=head2 getWeatherObj

This fetches the Weather::Underground object.

The only arguement accepted is the name of the local.

    my $wu=$zcw->getWeatherObj('someLocal');
    if($zcw->{error}){
        print "Error!";
    }

=cut

sub getWeatherObj{
	my $self=$_[0];
	my $name=$_[1];

	$self->errorblank;

	#error if no local is defined
	if (!defined($name)) {
		$name=$self->getDefaultLocal;
		if ($self->{error}) {
			$self->{error}=16;
			$self->{errorString}='getDefaultLocal errors and no local is specified.';
			warn('ZConf-Weather getWeatherObj:16: '.$self->{errorString});
			return undef;
		}
	}

	#local exists errored
	my $returned=$self->localExists($name);
	if ($self->{error}) {
		warn('ZConf-Weather getWeatherObj: localExists errored');
		return undef;
	}

	if (!$returned) {
		$self->{error}=10;
		$self->{errorString}='The local "'.$name.'" does not exist.';
		warn('ZConf-Weather getWeatherObj:10: '.$self->{errorString});
		return undef;
	}

	#gets the keys for that will be used
	my $local=$self->{zconf}->{conf}{weather}{'locals/'.$name.'/local'};
    my $type=$self->{zconf}->{conf}{weather}{'locals/'.$name.'/type'};
	my $template;
	if ($type eq 'template') {
		$template=$self->{zconf}->{conf}{weather}{'locals/'.$name.'/template'};
	}

	#inits the weather object...
	my $weather=Weather::Underground->new(place=>$local);
	if (!$weather) {
		$self->{error}=11;
		$self->{errorString}='Failed to init the module Weather::Underground.';
		return undef;
		warn('ZConf-Weather getWeatherObj:11: '.$self->{errorString});
	}

	return $weather;
}

=head2 init

This initializes it or a new set.

If the specified set already exists, it will be reset.

One arguement is required and it is the name of the set. If
it is not defined, ZConf will use the default one.

    #creates a new set named foo
    $zcw->init('foo');
    if($zcw->{error}){
        print "Error!\n";
    }

    #creates a new set with ZConf choosing it's name
    $zcw->init();
    if($zcw->{error}){
        print "Error!\n";
    }

=cut

sub init{
	my $self=$_[0];
	my $set=$_[1];

	#blanks any previous errors
	$self->errorblank;

	my $returned = $self->{zconf}->configExists("weather");
	if(defined($self->{zconf}->{error})){
		warn("ZConf-Weather init:2: Could not check if the config 'weather' exists.".
			 " It failed with '".$self->{zconf}->{error}."', '"
			 .$self->{zconf}->{errorString}."'");
		$self->{error}=2;
		$self->{errorString}="Could not check if the config 'weather' exists.".
		                     " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
		return undef;
	}

	#create the config if it does not exist
	if (!$returned) {
		$self->{zconf}->createConfig("weather");
		if ($self->{zconf}->{error}) {
			warn("ZConf-Weather init:2: Could not create the ZConf config 'weather'.".
				 " It failed with '".$self->{zconf}->{error}."', '"
				 .$self->{zconf}->{errorString}."'");
			$self->{error}=2;
			$self->{errorString}="Could not create the ZConf config 'weather'.".
			                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
			return undef;
		}
	}

	#create the new set
	$self->{zconf}->writeSetFromHash({config=>"weather", set=>$set},{});
	#error if the write failed
	if ($self->{zconf}->{error}) {
		warn("ZConf-Weather init:2: writeSetFromHash failed.".
			 " It failed with '".$self->{zconf}->{error}."', '"
			 .$self->{zconf}->{errorString}."'");
		$self->{error}=2;
		$self->{errorString}="writeSetFromHash failed.".
			                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
		return undef;
	}

	return 1;
}

=head2 listLocals

This gets a list of available locals.

    my @locals=$zcw->listLocals;
    if($zcw->{error}){
        print "Error!\n";
    }

=cut

sub listLocals{
	my $self=$_[0];

	$self->errorblank;

	my @localsA=$self->{zconf}->regexVarSearch('weather', '^locals/');
	if ($self->{zconf}->{error}) {
		warn('ZConf-Weather listLocals:2: ZConf error listing locals for the config "weather".'.
			 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			 'ZConf error string="'.$self->{zconf}->{errorString}.'"');
		$self->{error}=2;
		$self->{errorString}='ZConf error listing locals for the config "weather".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		return undef;
	}

	#removes templates/ from the beginning of the variable name
	my $int=0;
	my %locals;
	while (defined($localsA[$int])) {
		my @split=split(/\//, $localsA[$int]);
		$locals{$split[1]}='';

		$int++;
	}

	return keys(%locals);

}

=head2 listSets

This lists the available sets.

    my @sets=$zcw->listSets;
    if($zcw->{error}){
        print "Error!";
    }

=cut

sub listSets{
	my $self=$_[0];

	#blanks any previous errors
	$self->errorblank;

	my @sets=$self->{zconf}->getAvailableSets('weather');
	if($self->{zconf}->{error}){
		warn('ZConf-Weather listSets:2: ZConf error listing sets for the config "weather".'.
			 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			 'ZConf error string="'.$self->{zconf}->{errorString}.'"');
		$self->{error}=2;
		$self->{errorString}='ZConf error listing sets for the config "weather".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		return undef;
	}

	return @sets;
}

=head2 listTemplates

This gets a list of available templates.

    my @templates=$zcw->listTemplates;
    if($zcw->{error}){
        print "Error!\n";
    }

=cut

sub listTemplates{
	my $self=$_[0];

	$self->errorblank;

	my @templates=$self->{zconf}->regexVarSearch('weather', '^templates/');
	if ($self->{zconf}->{error}) {
		warn('ZConf-Weather listTemplates:2: ZConf error listing templates for the config "weather".'.
			 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			 'ZConf error string="'.$self->{zconf}->{errorString}.'"');
		$self->{error}=2;
		$self->{errorString}='ZConf error listing templates for the config "weather".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		return undef;
	}

	#removes templates/ from the beginning of the variable name
	my $int=0;
	while (defined($templates[$int])) {
		$templates[$int]=~s/^templates\///;

		$int++;
	}

	return @templates;
}

=head2 localExists

This makes sure a specified local exists.

    my $returned=$zcw->localExists('somelocal');
    if($zcw->{error}){
        print "Error!\n";
    }else{
        if($returned){
            print "It exists.\n";
        }
    }

=cut

sub localExists{
	my $self=$_[0];
	my $local=$_[1];

	$self->errorblank;

	my @locals=$self->listLocals;
	if ($self->{error}) {
		warn('ZConf-Weather localExists:2: listLocals errored');
		return undef;
	}

	my $int=0;
	while (defined($locals[$int])) {
		if ($locals[$int] eq $local) {
			return 1;
		}
		
		$int++;
	}

	return undef;
}

=head2 readSet

This reads a specific set. If the set specified
is undef, the default set is read.

    #read the default set
    $zcw->readSet();
    if($zcr->{error}){
        print "Error!\n";
    }

    #read the set 'someSet'
    $zcw->readSet('someSet');
    if($zcr->{error}){
        print "Error!\n";
    }

=cut

sub readSet{
	my $self=$_[0];
	my $set=$_[1];

	
	#blanks any previous errors
	$self->errorblank;

	$self->{zconf}->read({config=>'weather', set=>$set});
	if ($self->{zconf}->{error}) {
		warn('ZConf-Weather readSet:2: ZConf error reading the config "weather".'.
			 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			 'ZConf error string="'.$self->{zconf}->{errorString}.'"');
		$self->{error}=2;
		$self->{errorString}='ZConf error reading the config "weather".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		return undef;
	}

	return 1;
}

=head2 run

This acts on a local using it's defined type.

    $zcw->run('someLocal');
    if($zcw->{error}){
        print "Error!\n";
    }

=cut

sub run{
	my $self=$_[0];
	my $name=$_[1];

	#blank any previous errors
	$self->errorblank;

	#try to get it if no local is given
	if (!defined($name)) {
		$name=$self->getDefaultLocal;
		if ($self->{error}) {
			warn('ZConf-Weather run: No local was given and getDefaultLocal failed.');
			return undef;
		}
	}

	#gets the weather
	my $arrayref = $self->getWeather($name);
	if (!$arrayref) {
		warn('ZConf-Weather run:12: Failed to fetch the weather');
		$self->{error}=12;
		$self->{errorString}='Failed to fetch the weather';
		return undef;
	}

	#gets the keys for that will be used
	my $local=$self->{zconf}->{conf}{weather}{'locals/'.$name.'/local'};
    my $type=$self->{zconf}->{conf}{weather}{'locals/'.$name.'/type'};
	my $template;
	if ($type eq 'template') {
		$template=$self->{zconf}->{conf}{weather}{'locals/'.$name.'/template'};
	}

	#handles if if the type is set to dump
	if ($type eq 'dump') {
		foreach (@$arrayref) {
			while (my ($key, $value) = each %{$_}) {
				print $key."=".$value."\n";
			}
		}
		return 1;
	}

	#processes it if the type is set to template
	if ($type eq 'template') {
		#fetches the template
		my $t=$self->getTemplate($template);
		if ($self->{error}) {
			warn('ZConf-Weather run: getTemplate errored');
			return undef;
		}

		#inits the template object
		my $tobj=Text::NeatTemplate->new();

		#processes each one
		foreach (@$arrayref) {
			print $tobj->fill_in(data_hash=>%{$_},template=>$t);
		}
		return 1;
	}

	warn('ZConf-Weather run:14: The type, "'.$type.'", is not a valid type.');
	$self->{error}=14;
	$self->{errorString}='The type, "'.$type.'", is not a valid type.';

	return undef;
}

=head2 setLocal

This sets a local. If it does not exist, it will be created.
An already existing one will be overwriten.

=head3 argsHash

=head4 local

This is the local it is for.

=head4 name

This is name that will be used differentiating between the
various locals setup. It needs to be a valid ZConf set name.

=head4 type

This is what to do with it after downloading it.

=head4 template

The template to use if 'type' is set to 'template'.

=cut

sub setLocal{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	#blanks any previous errors
	$self->errorblank;

	#makes sure a locality is defined... this is the only one really needed...
	if (!defined($args{local})) {
	    warn('ZConf-Weather addLocal:3: No local defined in %args');
	    $self->{error}=3;
	    $self->{errorString}='No local defined in %args';
	    return undef;
	}

	#error if the type is not defined
	if (!defined($args{type})) {
	    warn('ZConf-Weather addLocal:3: No type defined in %args');
	    $self->{error}=5;
	    $self->{errorString}='No type defined in %args';
	    return undef;
	}

	#error if the type is not print or template
	if (($args{type} ne 'print') || ($args{type} ne 'template')) {
	    warn('ZConf-Weather addLocal:3: "'.$args{type}.' is not a valid type');
	    $self->{error}=8;
	    $self->{errorString}='"'.$args{type}.' is not a valid type';
	    return undef;
	}

	#make sure it is a legit name
	if (!defined($self->{zconf}->setNameLegit($args{name}))) {
	    warn('ZConf-Weather addLocal:4: Name is not a valid name');
	    $self->{error}=4;
	    $self->{errorString}='Name is not a valid name.';
	    return undef;		
	}

	if ($args{type} eq 'template') {
		#error if no template is specified
		if (!defined($args{template})) {
			warn('ZConf-Weather addLocal:6: No template defined in %args');
			$self->{error}=6;
			$self->{errorString}='No template defined in %args';
			return undef;
		}

		#return if templateExists errored
		my $returned=$self->templateExists($args{template});
		if ($self->{error}) {
			warn('ZConf-Weather addLocal: templateExists errored');
			return undef;
		}
	}

	#set the ZConf var for local
	$self->{zconf}->setVar('weather', 'locals/'.$args{name}.'/local', $args{local});
	#we only need to check this once as if it works once
	#it will work for the others
	if ($self->{zconf}->{error}) {
		warn('ZConf-Weather addLocal:2: Error set the variable "locals/'.$args{name}.'/local"'.
			 'for "weather" ZConf error="'.$self->{zconf}->{error}.'" '.
			 'ZConf error string="'.$self->{zconf}->{errorString}.'"');
		$self->{error}=2;
		$self->{errorString}=' Error set the variable "locals/'.$args{name}.'/local"'.
		                     'for "weather" ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		return undef;
	}

	#sets the template
	$self->{zconf}->setVar('weather', 'locals/'.$args{name}.'/type', $args{type});

	#only set the template if it is set to it
	if ($args{type} eq 'template') {
		#set the template if the type is set to #template
		$self->{zconf}->setVar('weather', 'locals/'.$args{name}.'/type', $args{type});
	}

	return 1;
}

=head2 setTemplate

This sets a specified template to the given value.

    $zcw->setTemplate($templateName, $template);
    if ($zcw->{error}) {
        print "Error!\n";
    }

=cut

sub setTemplate{
	my $self=$_[0];
	my $name=$_[1];
	my $template=$_[2];

	#blanks any previous errors
	$self->errorblank;

	#make sure a name for the template is specified
	if (!defined($name)) {
		warn('ZConf-Weather getTemplate:6: No template name specified');
		$self->{error}=6;
		$self->{errorstring}='No template specified.';
		return undef;
	}

	#make sure a template is specified
	if (!defined($template)) {
		warn('ZConf-Weather getTemplate:9: No template specified');
		$self->{error}=9;
		$self->{errorstring}='No template specified.';
		return undef;
	}

	$self->{zconf}->setVar('weather', 'templates/'.$name, $template);
	if ($self->{zconf}->{error}) {
		warn('ZConf-Weather setTemplate:2: Error set the variable "templates/'.$name.'"'.
			 'for "weather" ZConf error="'.$self->{zconf}->{error}.'" '.
			 'ZConf error string="'.$self->{zconf}->{errorString}.'"');
		$self->{error}=2;
		$self->{errorString}=' Error set the variable "templates/'.$name.'"'.
		                     'for "weather" ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		return undef;
	}

	return 1;
}

=head2 templateExists

This makes sure a specified template exists.

    my $returned=$zcw->templateExists('someTemplate');
    if($zcw->{error}){
        print "Error!\n";
    }else{
        if($returned){
            print "It exists.\n";
        }
    }

=cut

sub templateExists{
	my $self=$_[0];
	my $template=$_[1];

	$self->errorblank;

	my @templates=$self->listTemplates;
	if ($self->{error}) {
		warn('ZConf-Weather templateExists: listTemplates errored');
		return undef;
	}

	my $int=0;
	while (defined($templates[$int])) {
		if ($templates[$int] eq $template) {
			return 1;
		}
		
		$int++;
	}

	return undef;
}

=head2 errorblank

This blanks the error storage and is only meant for internal usage.

It does the following.

    $self->{error}=undef;
    $self->{errorString}="";

=cut

#blanks the error flags
sub errorblank{
        my $self=$_[0];

        $self->{error}=undef;
        $self->{errorString}="";

        return 1;
}

=head1 ERROR CODES

=head2 1

Could not initialize ZConf.

=head2 2

ZConf error.

=head2 3

No local defined.

=head2 4

Invalid set name.

=head2 5

No type specified.

=head2 6

No template name specified.

=head2 7

Non-existant template.

=head2 8

Invalid type specified.

=head2 9

No template specified.

=head2 10

Local does not exist.

=head2 11

Failed to init the module Weather::Underground.

=head2 12

Failed to fetch the weather.

=head2 13

Template does not exist.

=head2 14

The type is not valid.

=head2 15

No default local specified.

=head2 16

getDefaultLocal errors and no local is specified.

=head2 17

No default type specified.

=head1 ZConf Keys

=head2 Misc Keys

=head3 defaultLocal

This is the default local to act upon if not specified.

=head3 defaultType

This is the default thing to do.

=head3 defaultTemplate

This is the default template name to use.

=head2 Local Keys

=head3 locals/*/local

This is the location it is for. It can be specified as 'City',
'City, State', 'State', 'State, Country', or 'Country'.

=head3 locals/*/type

This specifies what should be done when fetching it.

=head4 dump

Prints it in 'variable=value' format.

=head4 template

This prints it using the specied template name. The template name being
'templates/<name>'.

=head2 Template Keys

=head3 templates/*

This is a template. For please see the section TEMPLATE for more information on
the keys and etc.

'*' can be any zconf compatible var name.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zconf-weather at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZConf-Weather>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZConf::Weather


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ZConf-Weather>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ZConf-Weather>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ZConf-Weather>

=item * Search CPAN

L<http://search.cpan.org/dist/ZConf-Weather>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ZConf::Weather
