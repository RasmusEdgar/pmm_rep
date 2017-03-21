#!/usr/bin/perl

use strict;
use warnings;
use Config::Auto;
use DateTime;
use Email::Stuffer;
use HTML::Strip;
use Mojo::UserAgent;
use Mojo::Template;
use Text::Wrap;
use utf8;
use v5.10;

# Fetch settings
my $config = Config::Auto::parse("../config/config", format => "perl");
my $html_mail_template = $config->{html_mail_template};
my $text_mail_template = $config->{text_mail_template};
my $recipients = $config->{recipients};
my $sender = $config->{sender};
my $basic_auth = $config->{basic_auth};
my $pmm_url = $config->{pmm_url};
my $ssl = $config->{ssl};
my $range_begin_hhmmss = $config->{range_begin_hhmmss};
my $range_end_hhmmss = $config->{range_end_hhmmss};
my $intro = $config->{intro}; 
my $title_part = $config->{title_part}; 

# Text stuff
$Text::Wrap::columns = 79;
my $hs = HTML::Strip->new();

# Time stuff
my $now = DateTime->now;
my $today = $now->ymd;

# Get last monday regardless of week day.
my $last_monday = $now->subtract( days => ( $now->day_of_week_0 || 7 ) );
$last_monday = $last_monday->ymd;

my $title = "${title_part}: $last_monday - $today";

# Build url
sub url_build {
  my ( $pmm_url, $last_monday, $today, $range_begin_hhmmss, $range_end_hhmmss ) = @_;
  my $ua = Mojo::UserAgent->new;
  if ( $ssl eq 'yes' ) {
    if ( $basic_auth eq 'yes' ) {
      my $user = $config->{user};
      my $password = $config->{password};
      my $response = $ua->get('https://'.$user.':'.$password.'@'.$pmm_url.'?begin='.$last_monday.'T'.$range_begin_hhmmss.'&end='.$today.'T'.$range_end_hhmmss.'&offset=0')->result->json;
      return my $repdataq = $response->{Query};
    } else {
      my $response = $ua->get('https://'.$pmm_url.'?begin='.$last_monday.'T'.$range_begin_hhmmss.'&end='.$today.'T'.$range_end_hhmmss.'&offset=0')->result->json;
      return my $repdataq = $response->{Query};
    }
  } else {
    if ( $basic_auth eq 'yes' ) {
      my $user = $config->{user};
      my $password = $config->{password};
      my $response = $ua->get('http://'.$user.':'.$password.'@'.$pmm_url.'?begin='.$last_monday.'T'.$range_begin_hhmmss.'&end='.$today.'T'.$range_end_hhmmss.'&offset=0')->result->json;
      return my $repdataq = $response->{Query};
    } else {
      my $response = $ua->get('http://'.$pmm_url.'?begin='.$last_monday.'T'.$range_begin_hhmmss.'&end='.$today.'T'.$range_end_hhmmss.'&offset=0')->result->json;
      return my $repdataq = $response->{Query};
    }
  }
}

my $repdataq = url_build( $pmm_url, $last_monday, $today, $range_begin_hhmmss, $range_end_hhmmss );

my $mt = Mojo::Template->new;

# Create intro
$intro = <<"INTRO";
$intro
INTRO

# Remove html tags for text part of mail
my $clean_intro = $hs->parse( $intro );

my $html = $mt->render_file( $html_mail_template, $title, $intro, $repdataq );
my $text = $mt->render_file( $text_mail_template, $title, $clean_intro, $repdataq );

my $wtext = wrap('', '', $text);

Email::Stuffer
    ->text_body($wtext)
    ->html_body($html)
    ->subject($title)
    ->from($sender)
    ->to($recipients)
    ->send;
