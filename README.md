# Flocking Simulation

Link to our resources: https://drive.google.com/drive/folders/1oUlCEtrgKMn2k3R5RPPJNN846DZGdXq-?usp=sharing

// Bug: Lags when boids lag when potentially getting too close?

NameName: Keith Rumbaua, Ho Chung, Daniel Mendes

Student Number: C20463336, C20348256, C20489272

Class Group: TU858

## Description of the project
This project is a simple Flocking simulation game, which the bird will separate when they too close, try to get close to each other when they meet other bird, and they also will face the same direction to move.

## How it work
To sucess the flocking simulation, we need three function, alignment, cohesion, separation.

Alignemt
This funciton is used to make the bird facing the same direction
- First, we get all the bird units volecity
- Second, we get the average of the volecity and multiple with the MAX speed. To prevent it go faster and faster, it also subtrast their orignal volecity to reset their speed.

Cohension
This function will make the birds slowly to get close together
- First, we get all the position of the birds
- Second, we find the center position with the birds and normlized this result to get the direction

Separation
This function is used to make the bird try to move away from other bird
- We get the dist between the bird itself and other birds
- Finally, we get the avarage of the separation and normalized this result to get the volecity

At the end
We add these 3 results with the Weight to get final volecity
