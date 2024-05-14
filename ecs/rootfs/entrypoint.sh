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

    # wait for ejabberd to fully start
    sleep 2

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


export JWT_SECRET=$(echo -n "$JWT_APP_SECRET" | base64 | tr -d '\n')
export XMPP_MUC_DOMAIN_PREFIX=$(echo -n "$XMPP_MUC_DOMAIN" | sed '/\..*//')

tpl /default/ejabberd.yml > /home/ejabberd/conf/ejabberd.yml

# for debugging
# cat /home/ejabberd/conf/ejabberd.yml

# need to run at background for ejabberd to start to run
register_jitsi_users &

# start ejabberd entrypoint
/sbin/tini -- /home/ejabberd/bin/ejabberdctl foreground "$@"
