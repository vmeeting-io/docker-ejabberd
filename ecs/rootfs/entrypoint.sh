#!/bin/sh
#
# initial configuration for ejabberd before starting ejabberd server
#
set -x

function register_jitsi_users {
    echo "Wait for ejabberd to be ready..."
    while ! nc -z localhost 5222; do
        sleep 1
    done

    cd /home/ejabberd/bin
    ./ejabberdctl unregister jvb auth.$XMPP_DOMAIN
    ./ejabberdctl register jvb auth.$XMPP_DOMAIN $JVB_AUTH_PASSWORD
    ./ejabberdctl unregister jibri auth.$XMPP_DOMAIN
    ./ejabberdctl register jibri auth.$XMPP_DOMAIN $JIBRI_XMPP_PASSWORD
    ./ejabberdctl unregister focus auth.$XMPP_DOMAIN
    ./ejabberdctl register focus auth.$XMPP_DOMAIN $JICOFO_AUTH_PASSWORD
    ./ejabberdctl unregister recorder recorder.$XMPP_DOMAIN
    ./ejabberdctl register recorder recorder.$XMPP_DOMAIN $JIBRI_RECORDER_PASSWORD
}


JWT_SECRET=$(echo -n "$JWT_APP_SECRET" | base64 | tr -d '\n')

# substitute variables in ejabberd.yml
sed -i \
    -e "s/{XMPP_DOMAIN}/$XMPP_DOMAIN/g" \
    -e "s/{JWT_SECRET}/$JWT_SECRET/g" \
    -e "s/{JICOFO_COMPONENT_SECRET}/$JICOFO_COMPONENT_SECRET/g" \
    -e "s/{DEFAULT_SITE_ID}/$DEFAULT_SITE_ID/g" \
    /home/ejabberd/conf/ejabberd.yml

# for debugging
cat /home/ejabberd/conf/ejabberd.yml


# need to run at background for ejabberd to start to run
register_jitsi_users &

# start ejabberd entrypoint
/home/ejabberd/bin/ejabberdctl foreground "$@"
