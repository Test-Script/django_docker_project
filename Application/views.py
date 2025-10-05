from django.shortcuts import render
# Create your views here.
# home/views.py
from django.shortcuts import render
from django.http import HttpResponse

def home(request):
    return HttpResponse("<h1>Let Check is Github Hook Working Properly or not</h1>")
