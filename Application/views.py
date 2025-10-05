from django.shortcuts import render
# Create your views here.
# home/views.py
from django.shortcuts import render
from django.http import HttpResponse

def home(request):
    return HttpResponse("<h1>Updating the changes here</h1>")
