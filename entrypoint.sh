echo "collecting static files..."
python manage.py collectstatic --noinput

echo "Applying database migrations..."
python manage.py migrate

echo "Starting the application..."
gunicorn core.wsgi:application --bind 0.0.0.0:8000
