#!/usr/bin/perl
use lib qw(/home/toshi/perl/lib);
use strict;
use warnings;
use URI;
use LWP::UserAgent;
use Encode qw( encode_utf8 );
use Config::Pit;
use JSON 'decode_json';
#use HashDump;
use feature qw( say );

{ package GooglePlusAPI;
	sub new {
		my $proto = shift;
		my $class = ref $proto || $proto;
		my $self = {};
		bless $self, $class;
		return $self;
	}
	sub pit_account {
		my $self = shift;
		if ( @_ ) {
			$self->{pit_account} = $_[0];
		}
		else{
			return print "Set pit_account\n";
		}
		my	$pit_account = $self->{pit_account};
		$self->{config} = Config::Pit::pit_get($pit_account, require => {
				"user_id"		 => "Google Plus user ID",
				"api_key"		 => "API Key",
			}
		);
		return $self->{pit_account};
	}	
	sub set_option {
		my ( $self, %args ) = @_;
		if ( @_) {
			$self->{option} = { %args };
			$self->init;
		}
		return $self->{option};
	}
	sub init {
		my $self = shift;
		my $option = $self->{option};
		my $config = $self->{config};

#		HashDump->load($option);
#		HashDump->load($config);

		my $api_method = '';

		if ($option->{get_type} eq 'get_post'){
				$api_method = 'people/';
		}elsif ($option->{get_type} eq 'profile'){
				$api_method = 'people/';
		}elsif ($option->{get_type} eq 'post_detail'){
				$api_method = 'activities/';
		}else{
			die "set correct options";
		}
		
		my $apiurl = 'https://www.googleapis.com/plus/v1/';
		$apiurl = $apiurl.$api_method;

		my $user_id = $self->{config}->{user_id};
		my $api_key = $self->{config}->{api_key};
		my $post_id = '';
		$post_id = $option->{post_id} if $option->{post_id};
		
		my $access_url;

		if ($option->{get_type} eq 'get_post'){
			$access_url = $apiurl . $user_id . '/activities/public?alt=json&key=' . $api_key;  
		}elsif ($option->{get_type} eq 'profile'){
			$access_url = $apiurl . $user_id . '?key=' . $api_key;  
		}elsif (($option->{get_type} eq 'post_detail') && $post_id){
			$access_url = $apiurl . $post_id . '/?key=' . $api_key;  
		}else{
			die "set correct options";
		}
		say "\n";
		$self->{access_url} = $access_url;
		return;
	}
	sub get {
		my $self = shift;
		my $uri = URI->new($self->{access_url});
#		say "uri = $uri";
		my $ua = LWP::UserAgent->new();
		$ua->default_header("HTTP_REFERER" => 'http://google.com' );
		my $body = $ua->get($uri);
		my $body_json =  Encode::decode_utf8($body->decoded_content);

		my $json = JSON::from_json($body_json);
#		HashDump->load($json);

		if ($self->{option}->{get_type} eq 'get_post') {
			my $content = \@{$json->{items}};
#			HashDump->load($content);
			$self->{content_data} = $content;
			return  $self->{content_data};
		}elsif ( $self->{option}->{get_type} eq 'profile'){
#			HashDump->load($json);
		  return $self->{profile_data} = $json;
		}elsif ( $self->{option}->{get_type} eq 'post_detail'){
			my $post_id = $self->{option}->{post_id};
			return $self->{post_details}->{$post_id} = $json;
		}
	}
}
1;


