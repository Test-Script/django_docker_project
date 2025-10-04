from django.shortcuts import render
# Create your views here.
# home/views.py
from django.shortcuts import render
from django.http import HttpResponse

def home(request):
    return HttpResponse("<h1> Testing the request-responce behavious of contianer communication between client & server</h1>")
