# Guacamole Session Recording

This example shows how you can enable Guacamole session recording, which allows you
to replay user sessions, either as video or as a typescript
(see https://guacamole.apache.org/doc/gug/recording-playback.html).

To enable this feature, you simply set `enable_session_recording = true` when using
the module.

Note that this feature uses a shared Elastic File System (EFS) across the ECS cluster,
which will incur additional costs.

To deploy the example, there is a two step process similar to the "full" example. The
first step deploys Guacamole, while the second step makes a Guacamole Terraform provider
and some example connections for you to play around with.
