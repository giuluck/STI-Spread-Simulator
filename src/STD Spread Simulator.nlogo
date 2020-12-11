globals [
  ;; DISEASE VARIABLES
  screening-probability
  initial-infected-percentage

  ;; SIMULATION VARIABLES
  warmup-time
  simulation-time
  breakup-probability
  single-probability
  casual-sex-probability

  ;; MODEL VARIABLES
  male-percentage
  average-semidegree
  rewiring-probability

  ;; VISUALIZATION VARIABLES
  ; gender visualization variables
  male-shape
  female-shape
  ; state visualization varibales
  susceptible-color
  exposed-color
  infected-color
  recovered-color
  ; graph visualization variables
  potential-color
  already-traced-color
  currently-traced-color
  casual-color
  stable-color
  ; graph visualization control variables
  spring-factor
  zero-degree-factor
  prev-layout
]

turtles-own [
  core?     ; whether or not the individual is in the core group
  status    ; sexual status ("Single", "Seek Casual", "Seek Stable", "Casual" or "Stable")
  spring-x  ; useful for the spring layout
  spring-y  ; useful for the spring layout
]

links-own [
  potential ; "none" if the link is not present in the potential partners network otherwise the corresponding color
  past      ; "none" if the link is not present in the past partners network otherwise the corresponding color
  current   ; "none" if the link is not present in the current partners network otherwise the corresponding color
]

to setup
  clear-all                                                                                     ;
  set-globals                                                                                   ; assign values to global variables
  initialize-population                                                                         ; initialize turtles and link properties and remove same-sex links from potential partners network
  create-potential-partners-network                                                             ; create small-world and scale-free potential partners networks (Klemm-Egquìlez model)
  repeat warmup-time [ simulate ]                                                               ; warm-up the simulation to form couples (2-years)
  ask n-of (initial-infected-percentage * population-size) turtles [ set color infected-color ] ; infect a certain percentage of turtles
  display-network                                                                               ; show the selected network
  reset-ticks                                                                                   ;
end

to go
  if ticks < simulation-time [ simulate ]                                                       ; it simulates only a given number of days
  display-network                                                                               ; but it always correctly displays the network
  tick                                                                                          ;
end

;; SETUP FUNCTIONS
to set-globals
  set screening-probability 1 / (52 * average-screening-time)        ; probability for an indivudual to be tested spontaneously
  set initial-infected-percentage 0.06                               ; initial infected population is 6%
  set warmup-time 100                                                ; number of days used to form relationships (around two years)
  set simulation-time 520                                            ; number of simulated days (around ten years)
  set breakup-probability 1 / 60                                     ; probability for a couple to slipt up
  set single-probability 1 / 30                                      ; probability for a single individual to be seeking a new relationship
  set casual-sex-probability 0.25                                    ; probability of seeking casual sex
  set male-percentage 0.5                                            ; probability for a node to be male
  set average-semidegree 15                                          ; half of the average number of potentials links including both sexes
  set rewiring-probability 0.25                                      ; probability to have a friend outside the spatial neighborhood
  set male-shape "circle"                                            ; circle turtles  (male)
  set female-shape "square"                                          ; square turtles  (female)
  set susceptible-color 9                                            ; white turtles   (susceptible)
  set exposed-color 45                                               ; yellow turtles  (exposed)
  set infected-color 15                                              ; red turtles     (infected)
  set recovered-color 55                                             ; green turtles   (recovered)
  set potential-color 95                                             ; sky blue links  (potential partners)
  set already-traced-color 5                                         ; grey links      (past partners met before last visit)
  set currently-traced-color 135                                     ; pink links      (past partners met after last visit)
  set casual-color 25                                                ; orange links    (current casual partners)
  set stable-color 65                                                ; lime links      (current stable partners)
  set spring-factor sqrt population-size                             ; used to regulate the spring forces
  set zero-degree-factor 5                                           ; used to display zero-degree nodes
end

to initialize-population
  create-turtles population-size [                                                           ;
    set shape female-shape                                                                   ; turtles are initialized to be female, susceptible, single and outside the core group
    set color susceptible-color                                                              ;
    set status "Single"                                                                      ;
    set core? false                                                                          ;
  ]                                                                                          ;
  ask n-of (male-percentage * population-size) turtles [ set shape male-shape ]              ; a given percentage of the population set to male shape
  ask n-of (core-group-percentage * population-size) turtles [                               ;
    set core? true                                                                           ; a given percentage of the population is part of the core group
    set shape word shape " 2"                                                                ; and their shape is changed accordingly
  ]                                                                                          ;
end

to create-potential-partners-network
  ask turtles [                                                                              ; to form the inital ring lattice
    let id who                                                                               ; every turtle creates half of the expected links with turtles on their right
    create-links-with other turtles with [                                                   ; as links are undirected, eventually they will get the other half of the links by turtles on their left
      (population-size + id - who) mod population-size <= average-semidegree                 ;
    ]                                                                                        ;
  ]                                                                                          ;
  ask links [                                                                                ; then, some links are rewired according to the Watts-Strogatz model
    if (random-float 1) < rewiring-probability [                                             ; namely each link can be rewired according to the rewiring-probability
      let extremity end1                                                                     ; when a link is chosen for rewiring
      if [ count link-neighbors ] of extremity < (count turtles - 1) [                       ; if the chosen extremity is not already fully connected
        ask one-of turtles with [ (self != extremity) and (not link-neighbor? extremity) ] [ ; one of its extremities is connected to a new one
          create-link-with extremity                                                         ;
        ]                                                                                    ;
        die                                                                                  ; and the previous link is removed
      ]                                                                                      ;
    ]                                                                                        ;
  ]                                                                                          ;
  ask links [                                                                                ;
    set potential potential-color                                                            ;
    set past "none"                                                                          ; links are initialized to be potential only, so there are no past or current partners
    set current "none"                                                                       ;
    if [shape] of end1 = [shape] of end2 [ die ]                                             ; and finally, same sex links are removed
  ]                                                                                          ;
end

;; GO FUNCTIONS
to simulate
  breakup-relationships                                                                                                                      ; breaking up the relationships
  update-status                                                                                                                              ; updating sexual statuses of the individuals
  form-pairs                                                                                                                                 ; forming new relationships
end

to display-network
  ask links [ set hidden? true ]                                                                                                             ; at each iteration, just the links of the chosen graph are shown
  if partners-network = "Potential" [ ask links with [ potential != "none" ] [ set hidden? false set color potential ] ]                     ;
  if partners-network = "Past" [ ask links with [ past != "none" ] [ set hidden? false set color past ] ]                                    ;
  if partners-network = "Current" [ ask links with [ current != "none" ] [ set hidden? false set color current ] ]                           ;
  if prev-layout != layout [                                                                                                                 ; whenever the graph layout is changed
    set prev-layout layout                                                                                                                   ; the according modality is used
    if layout = "Circle" [ layout-circle (sort turtles) max-pxcor - node-size ]                                                              ;
    if layout = "Random" [ ask turtles [ setxy random-xcor random-ycor ] ]                                                                   ;
    if layout = "Spring" [ ask turtles [ setxy spring-x spring-y ] ]                                                                         ;
  ]                                                                                                                                          ;
  if layout = "Spring" [                                                                                                                     ; also, if spring layout is being used
    layout-spring turtles links with [ hidden? = false ] 1 300 / spring-factor 150 / spring-factor                                           ; at each tick the turtles are moved accordingly
    ask turtles [ set spring-x xcor set spring-y ycor ]                                                                                      ; and the coordinates are maintained in order to be
  ]                                                                                                                                          ; restored when swapping from another modality to spring
  if-else proportional-sizes? [                                                                                                              ;
    let mean-degree mean [ count my-links with [ hidden? = false ] ] of turtles                                                              ; finally. turtle sizes are chosen according to the switch
    ask turtles [ set size node-size * (count my-links with [ hidden? = false ] + zero-degree-factor) / (mean-degree + zero-degree-factor) ] ;
  ] [                                                                                                                                        ;
    ask turtles [ set size node-size ]                                                                                                       ;
  ]                                                                                                                                          ;
end

; RELATIONSHIP FUNCTIONS
to breakup-relationships
  ask links with [ current != "none" ] [                                                    ; for all the currently active relationships
    if current = casual-color or random-float 1 < breakup-probability [                     ; if the relationship is causal or if it is stable but it breaks up
      ask both-ends [ set status "Single" ]                                                 ; individuals are made single again
      set current "none"                                                                    ; and the relationship is removed
    ]                                                                                       ;
  ]                                                                                         ;
end

to update-status
  ask turtles with [ status = "Single" ] [                                                  ; for each single turtle
    if random-float 1 < single-probability [                                                ; if it decides not to wait anymore
      if-else core? or random-float 1 < casual-sex-probability [                            ; set status either to
        set status "Seek Casual"                                                            ; "Seek Casual"
      ] [                                                                                   ; or
        set status "Seek Stable"                                                            ; "Seek Stable"
      ]                                                                                     ; according to the given probability
    ]                                                                                       ;
  ]                                                                                         ;
end

to form-pairs
  ask turtles with [ status = "Seek Casual" ] [                                             ; casual pairs formation:
    if status = "Seek Casual" [                                                             ; first, we check that turtles are still seeking (they may have been chosen by another one)
      let turtle-shape shape                                                                ;
      let partners other turtles with [                                                     ; for casual relationships, we do not look around the turtle's (potential) neighborhood
        shape != turtle-shape and                                                           ; so we retrieve every other turtle with different sex looking for casual sex
        status = "Seek Casual"                                                              ;
      ]                                                                                     ;
      if count partners > 0 [                                                               ; if there is at least one
        let partner one-of partners                                                         ; we retrieve one from the set randomly
        if not link-neighbor? partner [ create-link-with partner [ set potential "none" ] ] ; if a link is not present between the two turtles, we create it
        ask link-with partner [                                                             ; then we get the link and:
          set past currently-traced-color                                                   ; - set "past" to currently-traced so that contact tracing can be active for that
          set current casual-color                                                          ; - set "current" to casual
          ask both-ends [ set status "Casual" ]                                             ; - set the sexual status of both the individuals to casual
        ]                                                                                   ;
      ]                                                                                     ;
    ]                                                                                       ;
  ]                                                                                         ;
  ask turtles with [ status = "Seek Stable" ] [                                             ; stable pairs formation:
    if status = "Seek Stable" [                                                             ; first, we check that turtles are still seeking (they may have been chosen by another one)
      let turtle-shape shape                                                                ;
      let relationships my-links with [                                                     ; for stable relationships, we look around the turtle's (potential) neighborhood
        potential != "none" and                                                             ; so we retrieve every potential link with both individuals being in search for a stable relationship
        [ status ] of both-ends = [ "Seek Stable" "Seek Stable" ]                           ;
      ]                                                                                     ;
      if count relationships > 0 [                                                          ; if there is at least one
        ask one-of relationships [                                                          ; we retrive one from the set randomly and:
          set potential "none"                                                              ; - set "potential" to none so that a stable relationship between the two won't happen again
          set past currently-traced-color                                                   ; - set "past" to currently-traced so that contact tracing can be active for that
          set current stable-color                                                          ; - set "current" to stable
          ask both-ends [ set status "Stable" ]                                             ; - set the sexual status of both the individuals to stable
        ]                                                                                   ;
      ]                                                                                     ;
    ]                                                                                       ;
  ]                                                                                         ;
end

;; SPREADING-FUCTIONS
@#$#@#$#@
GRAPHICS-WINDOW
251
10
820
580
-1
-1
1.0
1
10
1
1
1
0
0
0
1
-280
280
-280
280
1
1
0
ticks
30.0

SLIDER
7
33
237
66
population-size
population-size
10
1000
100.0
10
1
NIL
HORIZONTAL

BUTTON
7
104
78
137
Setup
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
167
104
238
137
Go
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
0

CHOOSER
7
187
113
232
partners-network
partners-network
"Potential" "Past" "Current"
0

SWITCH
7
146
240
179
proportional-sizes?
proportional-sizes?
0
1
-1000

CHOOSER
122
187
240
232
layout
layout
"Circle" "Random" "Spring" "Stop"
0

SLIDER
8
395
238
428
infection-spread-probability
infection-spread-probability
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
8
437
238
470
contact-tracing-effectiveness
contact-tracing-effectiveness
0
1
0.8
0.01
1
NIL
HORIZONTAL

SLIDER
8
479
238
512
average-screening-time
average-screening-time
1
10
5.0
0.1
1
years
HORIZONTAL

SLIDER
7
238
240
271
node-size
node-size
1
20
10.0
1
1
NIL
HORIZONTAL

PLOT
1142
10
1493
244
Sexual Status
weeks
%
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"single" 1.0 0 -16777216 true "" "if ticks < simulation-time [\n  plot count turtles with [ status = \"Single\" ] / population-size * 100\n]"
"s-casual" 1.0 0 -8630108 true "" "if ticks < simulation-time [\n  plot count turtles with [ status = \"Seek Casual\" ] / population-size * 100\n]"
"s-stable" 1.0 0 -11221820 true "" "if ticks < simulation-time [\n  plot count turtles with [ status = \"Seek Stable\" ] / population-size * 100\n]"
"casual" 1.0 0 -955883 true "" "if ticks < simulation-time [\n  plot count turtles with [ status = \"Casual\" ] / population-size * 100\n]"
"stable" 1.0 0 -13840069 true "" "if ticks < simulation-time [\n  plot count turtles with [ status = \"Stable\" ] / population-size * 100\n]"

BUTTON
85
104
160
137
Go Once
go
NIL
1
T
OBSERVER
NIL
O
NIL
NIL
0

PLOT
826
10
1136
192
Number Of Sexual Partners Degree Distribution
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "plot-pen-reset\nlet max-degree max [count my-links with [ past != \"none\" ] ] of turtles\nlet min-degree min [count my-links with [ past != \"none\" ] ] of turtles\nset-plot-x-range min-degree (max-degree + 1)\nhistogram [count my-links with [ past != \"none\" ] ] of turtles"

SLIDER
8
356
238
389
core-group-percentage
core-group-percentage
0
1
0.1
0.01
1
NIL
HORIZONTAL

MONITOR
827
199
974
244
Non-Core Sexual Partners
mean [ count my-links with [ past != \"none\" ] ] of turtles with [ not core? ]
17
1
11

MONITOR
981
199
1135
244
Core Sexual Partners
mean [ count my-links with [ past != \"none\" ] ] of turtles with [ core? ]
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
setup
repeat 5 [rewire-one]
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="vary-rewiring-probability" repetitions="5" runMetricsEveryStep="false">
    <go>rewire-all</go>
    <timeLimit steps="1"/>
    <exitCondition>rewiring-probability &gt; 1</exitCondition>
    <metric>average-path-length</metric>
    <metric>clustering-coefficient</metric>
    <steppedValueSet variable="rewiring-probability" first="0" step="0.025" last="1"/>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
