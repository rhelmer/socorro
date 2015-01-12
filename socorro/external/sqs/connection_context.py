# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

import boto
import socket
import contextlib

from configman.config_manager import RequiredConfig
from configman import Namespace


#==============================================================================
class Connection(object):
    #--------------------------------------------------------------------------
    def __init__(self, config,  connection,
                 standard_queue_name='socorro.normal',
                 priority_queue_name='socorro.priority',
                 reprocessing_queue_name='socorro.reprocessing'):
        """Construct.

        parameters:
            config - a mapping containing
            connection - An Amazon SQS connection from boto
        """
        self.config = config
        self.connection = boto.sqs.connection
        self.standard_queue = conn.create_queue(standard_queue_name)
        self.priority_queue = conn.create_queue(priority_queue_name)
        self.reprocessing_queue = conn.create_queue(reprocessing_queue_name)

    #--------------------------------------------------------------------------
    def commit(self):
        pass

    #--------------------------------------------------------------------------
    def rollback(self):
        pass

    #--------------------------------------------------------------------------
    def close(self):
        self.connection.close()


#==============================================================================
class ConnectionContext(RequiredConfig):
    """A factory object in the form of a functor.  It returns connections
    to SQS wrapped in the minimal Connection class above.  Suitable for
    use in a "with" statment this class will handle opening a connection to
    SQS and its subsequent closure.  Use this class only when connections
    are never reused outside of the context for which they were created."""
    #--------------------------------------------------------------------------
    # configman parameter definition section
    required_config = Namespace()
    required_config.add_option(
        'access_key',
        doc="access key",
        default="",
        reference_value_from='resource.sqs',
    )
    required_config.add_option(
        'secret_access_key',
        doc="secret access key",
        default="",
        secret=True,
        reference_value_from='secrets.sqs',
    )
    required_config.add_option(
        name='standard_queue_name',
        default='socorro.normal',
        doc="the name of standard crash queue name within SQS",
        reference_value_from='resource.sqs',
    )
    required_config.add_option(
        name='priority_queue_name',
        default='socorro.priority',
        doc="the name of priority crash queue name within SQS",
        reference_value_from='resource.ss',
    )
    required_config.add_option(
        name='reprocessing_queue_name',
        default='socorro.reprocessing',
        doc="the name of reprocessing crash queue name within SQS",
    )
    required_config.add_option(
        name='sqs',
        default=Connection,
        doc="a classname for the type of wrapper for SQS connections",
        reference_value_from='resource.sqs',
    )

    #--------------------------------------------------------------------------
    def __init__(self, config, local_config=None):
        """Initialize the parts needed to start making SQS connections

        parameters:
            config - the complete config for the app.  If a real app, this
                     would be where a logger or other resources could be
                     found.
            local_config - this is the namespace within the complete config
                           where the actual SQS parameters are found"""
        super(ConnectionContext, self).__init__()
        self.config = config
        if local_config is None:
            local_config = config
        self.local_config = local_config

        # if a connection raises one of these exceptions, then they are
        # considered to be retriable exceptions.  This class does not implement
        # any retry behaviors itself, but just provides this information
        # about the connections it produces.  This is to facilitate a client
        # of this class to define its own retry or transaction behavior.
        # The information is used by the TransactionExector classes
# FIXME determine exceptions
#        self.operational_exceptions = (
#          pika.exceptions.AMQPConnectionError,
#          pika.exceptions.ChannelClosed,
#          pika.exceptions.ConnectionClosed,
#          pika.exceptions.NoFreeChannels,
#          socket.timeout)
        # conditional exceptions are amibiguous in their eligibilty to
        # trigger a retry behavior.  They're listed here so that custom code
        # written in the 'is_operational_exception' method can examine them
        # more closely and make the determination.  No ambiguous exceptions
        # have been identified, if and or when they are identified, they should
        # be entered here.
        self.conditional_exceptions = ()

    #--------------------------------------------------------------------------
    def connection(self, name=None):
        """create a new SQS connection, set it up for our queues, then
        return it wrapped with our connection class.

        parameters:
            name - unused in this context
        """
        bare_sqs_connection = boto.sqs.connection.SQSConnection()
        # FIXME hardcoded region name
        bare_sqs_connection.DefaultRegionName = 'us-west-2'

        wrapped_connection = \
            self.local_config.sqs_connection_wrapper_class(
                self.config,
                bare_sqs_connection,
                self.local_config.standard_queue_name,
                self.local_config.priority_queue_name,
                self.local_config.reprocessing_queue_name,
            )
        return wrapped_connection

    #--------------------------------------------------------------------------
    @contextlib.contextmanager
    def __call__(self, name=None):
        """returns an SQS connection wrapped in a contextmanager.

        The context manager will assure that the connection is closed but will
        not try to commit or rollback lingering transactions.

        parameters:
            name - an optional name for the SQS connection"""
        wrapped_sqs_connection = self.connection(name)
        try:
            yield wrapped_sqs_connection
        finally:
            self.close_connection(wrapped_sqs_connection)

    #--------------------------------------------------------------------------
    def close_connection(self, connection, force=False):
        """close the connection passed in.

        This function exists to allow derived classes to override the closing
        behavior.

        parameters:
            connection - the SQS connection object
            force - unused boolean to force closure; used in derived classes
        """
        connection.close()

    #--------------------------------------------------------------------------
    def close(self):
        """close any pooled or cached connections.  Since this base class
        object does no caching, there is no implementation required.  Derived
        classes may implement it."""
        pass

    #--------------------------------------------------------------------------
    def force_reconnect(self):
        """since this class uses a model where connections are opened and
        closed within the bounds of a context manager, this method is a
        No Op.  Derived classes may choose to do otherwise."""
        pass

    #--------------------------------------------------------------------------
    def is_operational_exception(self, msg):
        """Sometimes a resource connection can raise an ambiguous exception.
        The exception could either be an OperationalException (therefore
        eligible to be retried) or an unrecoverable exception.  This function
        is for implementation of code that make the determination.  No such
        exception have yet been identified.  """
        return False
