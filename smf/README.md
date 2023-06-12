# Networking for Images

We need to configure interfaces for the guest zone. The cleanest way to do
this is using `smfgen`.

Here, we've written the SMF service manifest in JSON and used `smfgen` to
generate the XML. If you need to modify the service definition, edit the
JSON then run the following before committing your changes.

    smfgen < smf.json > smf.xml

You *must* commit the `smf.xml` file. Build zones that already have the
service imported will not automatically import the new version. So you'll
need to deal with that.
