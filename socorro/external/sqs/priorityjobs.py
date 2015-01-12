# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from socorro.external import MissingArgumentError
from socorro.lib import external_common


class Priorityjobs(object):
    """Implement the /priorityjobs service with SQS."""

    def __init__(self, *args, **kwargs):
        self.config = kwargs.get('config').sqs
        self.context = self.config.sqs_class(self.config)

    def get(self, **kwargs):
        # TODO investigate and see if this is true
        raise NotImplementedError(
            'SQS does not support queue introspection.'
        )

    def create(self, **kwargs):
        """Add a new job to the priority queue
        """
        filters = [
            ("uuid", None, "str"),
        ]
        params = external_common.parse_arguments(filters, kwargs)

        if not params.uuid:
            raise MissingArgumentError('uuid')

        with self.context() as connection:
            try:
                self.config.logger.debug(
                    'Inserting priority job into SQS %s', params.uuid
                )

                connection.priority_queue.write(params.uuid)
            except ChannelClosed:
                self.config.logger.error(
                    "Failed inserting priorityjobs data into SQS",
                    exc_info=True
                )
                return False

        return True
