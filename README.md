# Percona Monitoring and Management Query Analytics reporting  

I couldn't find a tool which could generate weekly "Query Analytics" reports for our developers, so I wrote pmm\_rep to solve this problem.

This script will fetch data from the PMM qan-api and create a multipart email report containing both a html and a 79 width column fixed text version.

NOTE: The script is hardcoded to set begin date to the preceding monday. This should be pretty straightforward to change to something else.

## Prerequisites  

I recommend that this script runs in a local::lib environment and there is a postfix/ssmtp/sendmail relay service running on the platform (Linux) where you choose deploy it.

## Installation

1. Create a dedicated user.
   <pre><code class="bash">sudo useradd -d /opt/pmm_reporter -m -s /bin/bash -c"pmm reporter" pmm_reporter
   sudo su - pmm_reporter</code></pre>
1. Run the following as the dedicated user to set up a local::lib environment: 
   <pre><code class="shell">wget -O- https://cpanmin.us | perl - -l $HOME/perl5 App::cpanminus local::lib && echo 'eval `perl -I $HOME/perl5/lib/perl5 -Mlocal::lib`' >> $HOME/.bash_profile && echo 'export MANPATH=$HOME/perl5/man:$MANPATH' >> $HOME/.bash_profile
   . .bash_profile</code></pre>
1. Install the following dependencies with cpanm again as the dedicated user:
   <pre><code class="shell">cpanm ExtUtils::MakeMaker Mojolicious Text::Wrap Email::Stuffer Sub::Identify namespace::autoclean DateTime HTML::Strip Config::Auto</code></pre>
1. Clone the repository:
   <pre><code class="bash">git clone https://github.com/RasmusEdgar/pmm_rep.git</code></pre>
1. Copy and adjust config:
   <pre><code class="bash">cp ./pmm_rep/config/config.example ./pmm_rep/config/config && vim ./pmm_rep/config/config</code></pre>
1. Test if script is working by running it by hand.
   <pre><code class="bash">cd ./pmm_rep/script && ./pmm_rep.pl</code></pre>
1. Schedule a cronjob:
   <pre><code>PATH=/opt/pmm_reporter/perl5/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/opt/pmm_reporter/.local/bin:/opt/pmm_reporter/bin
   PERL5LIB=/opt/pmm_reporter/perl5/lib/perl5
   PERL_MM_OPT=INSTALL_BASE=/opt/pmm_reporter/perl5
   30 10 * * 1 cd /opt/pmm_reporter/pmm_rep/script && ./pmm_rep.pl > /dev/null 2>&1</code></pre>
