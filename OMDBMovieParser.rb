#!/usr/bin/ruby
require 'csv'
require 'json'
require 'rest-client'
require 'uri'

class Movie
    attr_accessor :title
    attr_accessor :year
    attr_accessor :rating

    def initialize(title, year)
        @title = title
        @year = year
    end
end

class ScriptConfig
    attr_accessor :csvPath
    attr_accessor :apiURL
    attr_accessor :titleQuery
    attr_accessor :yearQuery
    attr_accessor :responseTarget
    attr_accessor :invalidResponses
    attr_accessor :outputPath
    attr_accessor :errorPath

    def initialize(csvPath, apiURL, titleQuery, yearQuery, responseTarget, invalidResponses, outputPath, errorPath)
        @csvPath = csvPath
        @apiURL = apiURL
        @titleQuery = titleQuery
        @yearQuery = yearQuery
        @responseTarget = responseTarget
        @invalidResponses = invalidResponses
        @outputPath = outputPath
        @errorPath = errorPath
    end
end

def logQueryError(responseCode, movieTitle, errorPath)
    errorFile = open(errorPath, 'a')
    errorFile << "Movie title: " + movieTitle + "\n"
    errorFile << "Error code: "
    errorFile << responseCode
    errorFile << "\n"
    errorFile.close
end

def logRatingError(movieTitle, movieRating, errorFilePath)
    errorFile = open(errorFilePath, "a")
    errorFile << "Rating is invalid for movie: " + movieTitle + "\n"
    errorFile << "Rating: " + movieRating + "\n"
    errorFile.close
end

def readFromCSV(movies, csvPath)
    moviesFromCSV = CSV.foreach(csvPath) do |row|
        movies << Movie.new(row[0], row[1])
    end
end

def queryOMDB(movieList, movieRatings, scriptConfig) 
    movieList.each do |m|
        blankYear = m.year.to_s.empty?

        if (blankYear)
            queryURI = URI.escape(scriptConfig.apiURL + scriptConfig.titleQuery + m.title)
        else
            queryURI = URI.escape(scriptConfig.apiURL + scriptConfig.titleQuery + m.title + scriptConfig.yearQuery + m.year)
        end

        response = RestClient.get queryURI

        if response.code != 200
            logQueryError(response.code, m.title, scriptConfig.errorPath)
        else
            parsedResponse = JSON.parse(response)
            m.rating = parsedResponse[scriptConfig.responseTarget] || "NIL";

            if (!scriptConfig.invalidResponses.include? m.rating) 
                movieRatings.store(m.title, m.rating); 
            else
                logRatingError(m.title, m.rating, scriptConfig.errorPath)
            end
        end
    end
end

def sortRatings(movieRatings, outputPath)
    sortedHash = movieRatings.sort_by { |k, v| v }.reverse
    outputFile = open(outputPath, 'a')
    sortedHash.each{ |k, v| outputFile << k + " -- " + v  + "\n" }
    outputFile.close
end

csvPath = "bestPictureNoms.csv"
apiURL = "http://omdbapi.com/"
titleQuery = "?t="
yearQuery = "&y="
responseTarget = "imdbRating"
invalidResponses = [ "N/A", "NIL" ]
outputPath = "ratingsOutput.txt"
errorPath = "errors.txt"

scriptConfig = ScriptConfig.new(csvPath, apiURL, titleQuery, yearQuery, responseTarget, invalidResponses, outputPath, errorPath)
movieList = []
movieRatings = Hash.new

readFromCSV(movieList, scriptConfig.csvPath)
queryOMDB(movieList, movieRatings, scriptConfig)
sortRatings(movieRatings, scriptConfig.outputPath)
