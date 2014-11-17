OMDb-BestPicture-Data
=====================

Summary: Queries the OMDb API for data from the Academy Awards Best Picture nominees/winners

build:
    bundle install

run:
    ruby OMDb-bestPicture-api.rb [oscarYear]

    argument "oscarYear" should be an integer ranging from 1-87 corresponding to the Oscar Year to query.

Using a csv file containing data from the Best Picture nominees and winners, this script queries the OMDb API for data corresponding to the matching film. Currently outputs title, rating, release date, genre, director, and IMDb rating. Future to-dos include allowing the user to specify which data to return from the API. 
