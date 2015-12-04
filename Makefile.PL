use strict;
use warnings;
require 5.008 ;
use utf8;

use lib qw(inc);
use ExtUtils::MakeMaker 5.16 ;
use Config;

#XXX i wonder if we should check for socket and poll...
my @defines = ('-DHAVE_SOCKET', '-DHAVE_POLL', qq/-DAMQ_PLATFORM='"Perl_$^O_$^V"'/);

my $has_openssl = `pkg-config --static --libs librabbitmq` =~ 'ssl';

if ( $has_openssl ) {
    push @defines, '-DNAR_HAVE_OPENSSL';
}

my %WriteMakefileArgs = (
    NAME            => 'Net::AMQP::RabbitMQ',
    VERSION_FROM    => 'RabbitMQ.pm',
    LICENSE         => 'mozilla_1_1',
    ABSTRACT_FROM   => 'RabbitMQ.pm',
    AUTHOR          => 'Mark Ellis <markellis@cpan.org>, Michael Stemle, Jr. <mstemle@cpan.org>',
    OBJECT          => "RabbitMQ.o perl_math_int64.o",
    OPTIMIZE        => $ENV{'OPTIMIZE'},
    DEFINE          => join( ' ', @defines ),
    LIBS            => `pkg-config --libs librabbitmq`,
    PREREQ_PM       => {
        'Math::Int64'      => '0.34',
        'Scalar::Util'     => '0',
        'XSLoader'         => '0',
    },
    TEST_REQUIRES   => {
        'Sys::Hostname'    => '0',
        'Test::More'       => '0',
        'Time::HiRes'      => '0',
    },
    META_MERGE        => {
        "meta-spec" => { version => 2 },
        "dynamic_config" => 1,
        "x_contributors" => [
            'jesus - Theo Schlossnagle <jesus@omniti.com>',
            'markellis - Mark Ellis <markellis@cpan.org>',
            'mstemle - Michael Stemle, Jr. <mstemle@cpan.org>',
            'drolsky - Dave Rolsky <autarch@urth.org>',
            'srezic - Slaven Rezić <slaven@rezic.de>',
            'armand - Armand Leclercq <marman.email@gmail.com>',
            'dburke - Daniel W Burke <dburke@addictmud.org>',
            'davsx - Dávid Kovács',
            'iron-s - Alexey Sheynuk',
            'ether - Karen Etheridge <ether@cpan.org>',
        ],
        resources => {
            bugtracker  => {
                web    => 'https://github.com/net-amqp-rabbitmq/net-amqp-rabbitmq/issues',
            },
            repository => {
                type => 'git',
                url => 'git://github.com/net-amqp-rabbitmq/net-amqp-rabbitmq.git',
                web => 'https://github.com/net-amqp-rabbitmq/net-amqp-rabbitmq',
            },
        },
    },
);

if (!eval { ExtUtils::MakeMaker->VERSION('6.6303') }) {
    $WriteMakefileArgs{BUILD_REQUIRES} = $WriteMakefileArgs{TEST_REQUIRES};
    delete $WriteMakefileArgs{TEST_REQUIRES};
}

WriteMakefile(%WriteMakefileArgs);
