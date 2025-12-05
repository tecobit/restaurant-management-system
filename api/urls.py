from django.urls import path

from .views import api_overview

urlpatterns = [
    path('oe/', api_overview, name='api-overview'),
]