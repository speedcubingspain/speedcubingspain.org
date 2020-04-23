apt-get update
apt-get install -y curl git vim htop apt-transport-https

# Create aes user if does not exist.
if ! id -u aes &>/dev/null; then
  useradd -m -s /bin/bash aes
  chown aes:aes /home/aes
fi

echo "Setting up ssh keys for members."

tmp_authorized_keys_path="/tmp/authorized_keys"
for user in albertopdrf ivan-brigidano; do
  public_keys_url="https://github.com/$user.keys"

  echo "" >> $tmp_authorized_keys_path
  echo "# Keys for $user" >> $tmp_authorized_keys_path
  curl -s $public_keys_url >> $tmp_authorized_keys_path
done

su aes -c "mkdir -p /home/aes/.ssh"
su aes -c "touch /home/aes/.ssh/authorized_keys"
mv /home/aes/.ssh/authorized_keys /home/aes/.ssh/authorized_keys.bak
chown aes:aes /tmp/authorized_keys
mv /tmp/authorized_keys /home/aes/.ssh


# Setting up rails and db

# Will hold environment variables with secrets
touch /tmp/secrets

echo "deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get update

apt-get install -y postgresql-10

user_exists=`sudo -u postgres psql -tAc "select 1 from pg_catalog.pg_roles where rolname='speedcubingspain';"`

if [ "x$user_exists" != "x1" ]; then
  password=`openssl rand -base64 16`
  sudo -u postgres psql -c "create role speedcubingspain login password '$password' createdb;"
  su aes -c "echo 'DATABASE_PASSWORD=$password' >> /home/aes/.env.production"
fi

# to build rbenv
apt-get install -y autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm3 libgdbm-dev gcc g++ make

# install nodejs and yarn
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
# install stretch backports for certbot
echo "deb http://ftp.debian.org/debian stretch-backports main" | tee /etc/apt/sources.list.d/certbot.list
# this runs apt-get update
curl -sL https://deb.nodesource.com/setup_10.x | bash -

# libpq-dev is for pg gem
apt-get install -y nodejs yarn libpq-dev

# for activestorage variants and previews
apt-get install -y imagemagick
apt-get install -y poppler-utils

# for certbot
apt-get install -y python-certbot-nginx -t stretch-backports

if [ ! -d /home/aes/speedcubingspain.org ]; then
  su aes -c "cd /home/aes && git clone https://github.com/speedcubingspain/speedcubingspain.org.git /home/aes/speedcubingspain.org"
fi
apt-get install -y nginx
cp /home/aes/speedcubingspain.org/prod_conf/aes.conf /etc/nginx/conf.d/
cp /home/aes/speedcubingspain.org/prod_conf/pre_certif.conf /etc/nginx/conf.d/
# Create an empty https conf since we don't have a certificate yet
touch /etc/nginx/aes_https.conf

service nginx restart

read -p "Do you want to create a new certificate for the server? (N/y)" user_choice
if [ "x$user_choice" == "xy" ]; then
  /home/aes/speedcubingspain.org/scripts/prod_cert.sh create_cert
  cp /home/aes/speedcubingspain.org/prod_conf/aes_https.conf /etc/nginx/
  rm /etc/nginx/conf.d/pre_certif.conf
  cp /home/aes/speedcubingspain.org/prod_conf/post_certif.conf /etc/nginx/conf.d/
  service nginx restart
fi

echo "Installing cron scripts"
cp /home/aes/speedcubingspain.org/scripts/cert_nginx /etc/cron.weekly

echo "Bootstraping as aes"
su aes -c "cd /home/aes && /home/aes/speedcubingspain.org/scripts/aes_bootstrap.sh"
