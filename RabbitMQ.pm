package Net::AMQP::RabbitMQ;
use strict;
use warnings;

our $VERSION = '1.400000';

use XSLoader;
XSLoader::load "Net::AMQP::RabbitMQ", $VERSION;
use Scalar::Util qw(blessed);

=encoding UTF-8

=head1 NAME

Net::AMQP::RabbitMQ - interact with RabbitMQ over AMQP using librabbitmq

=head1 SYNOPSIS

  use Net::AMQP::RabbitMQ;
  my $mq = Net::AMQP::RabbitMQ->new();
  $mq->connect("localhost", { user => "guest", password => "guest" });
  $mq->channel_open(1);
  $mq->publish(1, "queuename", "Hi there!");
  my $gotten = $mq->get(1, "queuename");
  print $gotten->{body} . "\n";
  $mq->disconnect();

=head1 VERSION COMPATIBILITY

This module was forked from L<Net::RabbitMQ> version 0.2.6 which uses an older
version of librabbitmq, and doesn't work correctly with newer versions of RabbitMQ.
The main change between this module and the original is this library uses
a newer, unforked, version of librabbitmq. Version 0.7.1 to be precise.

This means this module only works with the AMQP 0.9.1 protocol, so requires RabbitMQ
version 2+. Also, since the version of librabbitmq used is not a custom fork, it
means this module doesn't support the basic_return callback method.

=head1 DESCRIPTION

C<Net::AMQP::RabbitMQ> is a fork of C<Net::RabbitMQ> that uses a newer version of librabbitmq
and fixes some bugs. It provides a simple wrapper around the librabbitmq library
that allows connecting, declaring exchanges and queues, binding and unbinding
queues, publishing, consuming and receiving events.

Error handling in this module is primarily achieve by C<Perl_croak> (die). You
should be making good use of eval around these methods to ensure that you
appropriately catch the errors.

=head1 METHODS

All methods, unless specifically stated, return nothing on success
and die on failure.

Failure to be connected is a fatal failure for most methods.

=head2 new()

Creates a new Net::AMQP::RabbitMQ object.

=head2 connect( $hostname, $options )

C<$hostname> is the host to which a connection will be attempted.

C<$options> is an optional hash respecting the following keys:

    {
        user            => $user,        #default 'guest'
        password        => $password,    #default 'guest'
        port            => $port,        #default 5672
        vhost           => $vhost,       #default '/'
        channel_max     => $cmax,        #default 0
        frame_max       => $fmax,        #default 131072
        heartbeat       => $hearbeat,    #default 0
        timeout         => $seconds      #default undef (no timeout)

        ssl             => 1 | 0         #default 0
        ssl_verify_host => 1 | 0         #default 1
        ssl_cacert      => $caert_path   #needed for ssl
        ssl_init        => 1 | 0         #default 1, initilise the openssl library
    }

You probably don't want to touch C<ssl_init>, unless you know what it does.

For now there is no option to disable ssl peer checking, meaning to use C<ssl>, C<ssl_cacert> is required.

B<SSL NOTE>

if the connection is cut when using ssl, openssl will throw a C<SIGPIPE>, you should catch this or perl
will exit with error code 141

    $SIG{PIPE} = 'IGNORE';

=head2 disconnect()

Causes the connection to RabbitMQ to be torn down.

=head2 get_server_properties()

Get a hashref of server properties (these may vary, you should C<Data::Dumper> to inspect). They will be provided by the RabbitMQ server to which you are connected.

=head2 get_client_properties()

Get a hashref of server properties (these may vary, you should C<Data::Dumper> to inspect).

=head2 is_connected()

Returns true if a valid socket connection appears to exist, false otherwise.

=head2 channel_open($channel)

C<$channel> is a positive integer describing the channel you which to open.

=head2 channel_close($channel)

C<$channel> is a positive integer describing the channel you which to close.

=head2 get_channel_max()

Returns the maximum allowed channel number.

=head2 exchange_declare($channel, $exchange, $options, $arguments)

C<$channel> is a channel that has been opened with C<channel_open>.

C<$exchange> is the name of the exchange to be instantiated.

C<$options> is an optional hash respecting the following keys:

     {
       exchange_type => $type,  #default 'direct'
       passive => $boolean,     #default 0
       durable => $boolean,     #default 0
       auto_delete => $boolean, #default 1
     }

C<$arguments> is an optional hash of additional arguments to the RabbitMQ server, such as:

     {
       # exchange to try if no routes apply on this exchange
       alternate_exchange => 'alternate_exchange_name',
     }

=head2 exchange_delete($channel, $exchange, $options)

C<$channel> is a channel that has been opened with C<channel_open>.

C<$exchange> is the name of the exchange to be deleted.

C<$options> is an optional hash respecting the following keys:

     {
       if_unused => $boolean,   #default 1
     }

=head2 exchange_bind($channel, $destination, $source, $routing_key, $arguments)

C<$channel> is a channel that has been opened with C<channel_open>.

C<$destination> is a previously declared exchange, C<$source> is
yet another previously declared exchange, and C<$routing_key> is
the routing key that will bind the specified source exchange to
the specified destination exchange.

C<$arguments> is an optional hash which will be passed to the server.  When
binding to an exchange of type C<headers>, this can be used to only receive
messages with the supplied header values.

=head2 exchange_unbind($channel, $destination, $source, $routing_key, $arguments)

C<$channel> is a channel that has been opened with C<channel_open>.

C<$destination> is a previously declared exchange, C<$source> is
yet another previously declared exchange, and C<$routing_key> is
the routing key that will B<unbind> the specified source exchange from
the specified destination exchange.

C<$arguments> is an optional hash which will be passed to the server.  When
binding to an exchange of type C<headers>, this can be used to only receive
messages with the supplied header values.

=head2 queue_declare($channel, $queuename, $options, $arguments)

C<$channel> is a channel that has been opened with C<channel_open>.

C<$queuename> is the name of the queuename to be instantiated.  If
C<$queuename> is undef or an empty string, then an auto generated
queuename will be used.

C<$options> is an optional hash respecting the following keys:

     {
       passive => $boolean,     #default 0
       durable => $boolean,     #default 0
       exclusive => $boolean,   #default 0
       auto_delete => $boolean, #default 1
     }

C<$arguments> is an optional hash which will be passed to the server
when the queue is created.  This can be used for creating mirrored
queues by using the x-ha-policy header.

In scalar context, this method returns the queuename declared
(important for retrieving the autogenerated queuename in the
event that one was requested).

In array context, this method returns three items: queuename,
the number of message waiting on the queue, and the number
of consumers bound to the queue.

=head2 queue_bind($channel, $queuename, $exchange, $routing_key, $arguments)

C<$channel> is a channel that has been opened with C<channel_open>.

C<$queuename> is a previously declared queue, C<$exchange> is a
previously declared exchange, and C<$routing_key> is the routing
key that will bind the specified queue to the specified exchange.

C<$arguments> is an optional hash which will be passed to the server.  When
binding to an exchange of type C<headers>, this can be used to only receive
messages with the supplied header values.

=head2 queue_unbind($channel, $queuename, $exchange, $routing_key, $arguments)

This is like the C<queue_bind> with respect to arguments.  This command unbinds
the queue from the exchange.  The C<$routing_key> and C<$arguments> must match
the values supplied when the binding was created.

If this fails, you must reopen the channel

=head2 queue_delete($channel, $queuename, $options)

Deletes the queue

C<$options> is an optional hash respecting the following keys:

     {
       if_unused    => $boolean,     #default 1
       if_empty     => $boolean,     #default 1
     }

If this fails, you must reopen the channel

=head2 publish($channel, $routing_key, $body, $options, $props)

C<$channel> is a channel that has been opened with C<channel_open>.

C<$routing_key> is the name of the routing key for this message.

C<$body> is the payload to enqueue.

C<$options> is an optional hash respecting the following keys:

     {
       exchange => $exchange,                     #default 'amq.direct'
       mandatory => $boolean,                     #default 0
       immediate => $boolean,                     #default 0
       force_utf8_in_header_strings => $boolean,  #default 0
     }

The C<force_utf8_in_header_strings> option causes all headers which look like
strings to be treated as UTF-8. In an attempt to make this a non-breaking change,
this option is disabled by default. However, for all headers beginning with
C<x->, those are treated as UTF-8 regardless of this option (per spec).

C<$props> is an optional hash (the AMQP 'props') respecting the following keys:

     {
       content_type => $string,
       content_encoding => $string,
       correlation_id => $string,
       reply_to => $string,
       expiration => $string,
       message_id => $string,
       type => $string,
       user_id => $string,
       app_id => $string,
       delivery_mode => $integer,
       priority => $integer,
       timestamp => $integer,
       header => $headers # This should be a hashref of keys and values.
     }

=head2 consume($channel, $queuename, $options)

C<$channel> is a channel that has been opened with C<channel_open>.

C<$queuename> is the name of the queue from which we'd like to consume.

C<$options> is an optional hash respecting the following keys:

     {
       consumer_tag => $tag,    #absent by default
       no_local => $boolean,    #default 0
       no_ack => $boolean,      #default 1
       exclusive => $boolean,   #default 0
     }


The consumer_tag is returned.  This command does B<not> return AMQP
frames, it simply notifies RabbitMQ that messages for this queue should
be delivered down the specified channel.

=head2 recv($timeout)

C<$timeout> is a positive integer, specifying the number of milliseconds to
wait for a message. If you do not provide a timeout (or set it to 0), then
this call will block until it receives a message. If you set it to -1 it will
return immediately (waiting 0 ms).

This command receives and reconstructs AMQP frames and returns a hash
containing the following information:

     {
       body => 'Magic Transient Payload', # the reconstructed body
       routing_key => 'nr_test_q',        # route the message took
       exchange => 'nr_test_x',           # exchange used
       delivery_tag => 1,                 # (used for acks)
       redelivered => $boolean            # if message is redelivered
       consumer_tag => 'c_tag',           # tag from consume()
       props => $props,                   # hashref sent in
     }

C<$props> is the hash sent by publish()  respecting the following keys:

     {
       content_type => $string,
       content_encoding => $string,
       correlation_id => $string,
       reply_to => $string,
       expiration => $string,
       message_id => $string,
       type => $string,
       user_id => $string,
       app_id => $string,
       delivery_mode => $integer,
       priority => $integer,
       timestamp => $integer,
     }

If you provide a timeout, then the C<recv()> method returns C<undef> if the
timeout expires before a message is received from the server.

=head2 cancel($channel, $consumer_tag)

C<$channel> is a channel that has been opened with C<channel_open>.

C<$consumer_tag> is a tag previously passed to C<consume()> or one that was
generated automatically as a result of calling C<consume()> without an
explicit tag.

This method returns true or false indicating whether we got the expected
"cancel-ok" response from the server.

=head2 get($channel, $queuename, $options)

This command runs an amqp_basic_get which returns undef immediately
if no messages are available on the queue and returns a hash as follows
if a message is available:

    {
      body => 'Magic Transient Payload', # the reconstructed body
      routing_key => 'nr_test_q',        # route the message took
      exchange => 'nr_test_x',           # exchange used
      content_type => 'foo',             # (only if specified)
      delivery_tag => 1,                 # (used for acks)
      redelivered => 0,                  # if message is redelivered
      message_count => 0,                # message count

      # Not all of these will be present. Consult the RabbitMQ reference for more details.
      props => {
        content_type => 'text/plain',
        content_encoding => 'none',
        correlation_id => '123',
        reply_to => 'somequeue',
        expiration => 1000,
        message_id => 'ABC',
        type => 'notmytype',
        user_id => 'guest',
        app_id => 'idd',
        delivery_mode => 1,
        priority => 2,
        timestamp => 1271857990,
        headers => {
          unsigned_integer => 12345,
          signed_integer   => -12345,
          double           => 3.141,
          string           => "string here",

          # The x-death header is a special header for dead-lettered messages (rejected or timed out).
          'x-death' => [
            {
              time           => 1271857954,
              exchange       => $exchange,
              queue          => $exchange,
              reason         => 'expired',
              'routing-keys' => [q{}],
            },
          ],
        },
      },
    }

C<$channel> is a channel that has been opened with C<channel_open>.

C<$queuename> is the name of the queue from which we'd like to consume.

C<$options> is an optional hash respecting the following keys:

     {
       no_ack => $boolean,  #default 1
     }

=head2 ack($channel, $delivery_tag, $multiple = 0)

C<$channel> is a channel that has been opened with C<channel_open>.

C<$delivery_tag> the delivery tag seen from a returned frame from the
C<recv> method.

C<$multiple> specifies if multiple are to be acknowledged at once.

=head2 purge($channel, $queuename)

C<$channel> is a channel that has been opened with C<channel_open>.

C<$queuename> is the queue to be purged.

=head2 reject($channel, $delivery_tag, $requeue = 0)

C<$channel> is a channel that has been opened with C<channel_open>.

C<$delivery_tag> the delivery tag seen from a returned frame from the
C<recv> method.

C<$requeue> specifies if the message should be requeued.

=head2 tx_select($channel)

C<$channel> is a channel that has been opened with C<channel_open>.

Start a server-side (tx) transaction over $channel.

=head2 tx_commit($channel)

C<$channel> is a channel that has been opened with C<channel_open>.

Commit a server-side (tx) transaction over $channel.

=head2 tx_rollback($channel)

C<$channel> is a channel that has been opened with C<channel_open>.

Rollback a server-side (tx) transaction over $channel.

=head2 basic_qos($channel, $options)

C<$channel> is a channel that has been opened with C<channel_open>.

C<$options> is an optional hash respecting the following keys:

     {
       prefetch_count => $cnt,  #default 0
       prefetch_size  => $size, #default 0
       global         => $bool, #default 0
     }

Set quality of service flags on the current $channel.

=head2 heartbeat()

Send a heartbeat frame.  If you've connected with a heartbeat parameter,
you must send a heartbeat periodically matching connection parameter or
the server may snip the connection.

=head1 WARNING AND ERROR MESSAGES

=head2 Fatal Errors

It should be noted that almost all errors in this library are considered fatal,
insomuch as they trigger a C<croak()>.

=head1 AUTHORS

Theo Schlossnagle E<lt>jesus@omniti.comE<gt>

Mark Ellis E<lt>markellis@cpan.orgE<gt>

Michael Stemle, Jr. E<lt>themanchicken@gmail.comE<gt>

Dave Rolsky E<lt>autarch@urth.orgE<gt>

Slaven Rezić

Armand Leclercq

Daniel W Burke

Dávid Kovács

Alexey Sheynuk

Karen Etheridge E<lt>ether@cpan.orgE<gt>,

=head1 LICENSE

This software is licensed under the Mozilla Public License. See the LICENSE file in the top distribution directory for the full license text.

librabbitmq is licensed under the MIT License. See the LICENSE-MIT file in the top distribution directory for the full license text.

=cut

sub publish {
    my ($self, $channel, $routing_key, $body, $options, $props) = @_;

    $options ||= {};
    $props   ||= {};

    # Do a shallow clone to avoid modifying variable passed by caller
    $props = { %$props };

    # Convert blessed variables in headers to strings
    if( $props->{headers} ) {
        $props->{headers} = { map { blessed($_) ? "$_" : $_ } %{ $props->{headers} } };
    }

    $self->_publish($channel, $routing_key, $body, $options, $props);
}

1;
