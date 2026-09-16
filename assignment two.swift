
// easy

// 1
let fruits = ["Apple", "Banana", "Cherry", "Mango", "Orange"]
print("Third fruit: \(fruits[2])")

// 2
var favoriteNumbers: Set<Int> = [8, 88, 888, 8888]
favoriteNumbers.insert(88888)
print(favoriteNumbers)

// 3
let languages: [String: Int] = ["Swift": 2014, "Python": 1991, "Dart": 2013]
print(languages["Swift"]!)

// 4
var colors = ["Pink", "Blue", "Black", "White"]
colors[1] = "Red"
print(colors)


// medium

// 1
let setA: Set<Int> = [1, 2, 3, 4]
let setB: Set<Int> = [3, 4, 5, 6]
let intersectionResult = setA.intersection(setB)
print(intersectionResult)

// 2
var studentScores = ["Amira": 85, "Medina": 90, "Daniya": 78]
studentScores["Medina"] = 95
print(studentScores)

// 3. объединяем два массива
let firstFruits = ["apple", "banana"]
let secondFruits = ["cherry", "date"]
let allFruits = firstFruits + secondFruits
print(allFruits)


// hard

// 1
var countryPopulations = [
    "Armenia": 2952365,
    "Kazakhstan": 19000000,
    "Georgia": 3806671
]
countryPopulations["Luxembourg"] = 681973
print(countryPopulations)

// 2
let firstAnimal: Set<String> = ["cat", "dog"]
let secondAnimal: Set<String> = ["dog", "mouse"]
let unionResult = firstAnimal.union(secondAnimal)
let finalResult = unionResult.subtracting(secondAnimal)
print(finalResult)

// 3
let studentGrades: [String: [Int]] = [
    "Aldiyar": [67, 76, 88],
    "Ailin": [93, 84, 97]
]
print(studentGrades["Ailin"]![1])

