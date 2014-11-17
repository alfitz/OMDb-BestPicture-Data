#!/usr/bin/ruby
require 'csv'
require 'json'
require 'rest-client'
require 'uri'

class Movie
    attr_accessor :title
    attr_accessor :filmYear
    attr_accessor :rating
    attr_accessor :oscarYear
    attr_accessor :winner

    def initialize(title, filmYear, oscarYear, winner)
        @title = title
        @filmYear = filmYear
        @oscarYear = oscarYear
        @winner = winner
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

def readFromCSV(movies, csvPath, searchYear)
    moviesFromCSV = CSV.foreach(csvPath) do |row|
        if (row[2].to_i == searchYear)
            movies << Movie.new(row[0], row[1], row[2], row[3] || false)
        end
    end

    movies.each do |m|
        puts m.title + " " + m.filmYear + " " + m.oscarYear + " " + m.winner.to_s
    end
end

def queryOMDB(movieList, movieRatings, scriptConfig) 
    movieList.each do |m|
        blankYear = m.filmYear.to_s.empty?

        if (blankYear)
            queryURI = URI.escape(scriptConfig.apiURL + scriptConfig.titleQuery + m.title)
        else
            queryURI = URI.escape(scriptConfig.apiURL + scriptConfig.titleQuery + m.title + scriptConfig.yearQuery + m.filmYear)
        end

        response = RestClient.get queryURI

        if response.code != 200
            logQueryError(response.code, m.title, scriptConfig.errorPath)
        else
            parsedResponse = JSON.parse(response)
            m.rating = parsedResponse[scriptConfig.responseTarget] || "NIL";

            if (!scriptConfig.invalidResponses.include? m.rating) 
                movieRatings.store(m, parsedResponse); 
            else
                logRatingError(m.title, m.rating, scriptConfig.errorPath)
            end
        end
    end
end

def printMovieData(movieData, scriptConfig)
    outputFile = open(scriptConfig.outputPath, 'a')
    outputFile << "Nominee data for the "  + movieData.keys[0].oscarYear + " Annual Academy Awards \n\n"
    movieData.each { |k, v| 
        outputFile << k.title + "\n"
        outputFile << "Rating: " + v["Rated"] + "\n"
        outputFile << "Release Date: " + v["Released"] + "\n"
        outputFile << "Genre: " + v["Genre"] + "\n"
        outputFile << "Director: " + v["Director"] + "\n"
        if (k.winner)
            outputFile << "Won the Academy Award for Best Picture\n\n"
        else
            outputFile << "\n"
        end
    }
    outputFile.close
end

csvPath = "bestPictureNoms.csv"
apiURL = "http://omdbapi.com/"
titleQuery = "?t="
yearQuery = "&y="
responseTarget = "imdbRating"
invalidResponses = [ "N/A", "NIL" ]
outputPath = "queryOutput.txt"
errorPath = "errors.txt"

searchYear = ARGV[0].to_i
if (searchYear < 1 || searchYear > 86 )
    abort("Argument must be a valid Oscar year (between 1 and 86)")
end

scriptConfig = ScriptConfig.new(csvPath, apiURL, titleQuery, yearQuery, responseTarget, invalidResponses, outputPath, errorPath)
movieList = []
movieData = Hash.new

readFromCSV(movieList, scriptConfig.csvPath, searchYear)
queryOMDB(movieList, movieData, scriptConfig)
printMovieData(movieData, scriptConfig)
