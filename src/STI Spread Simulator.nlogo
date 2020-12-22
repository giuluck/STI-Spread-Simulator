;; STD SPREAD SIMULATOR
;; Luca Giuliani
;; luca.giuliani10@studio.unibo.it
;; 0000933791

globals [
  ;; DISEASE VARIABLES
  actual-recovery-time
  delay-rate
  screening-probability

  ;; SEXUAL VARIABLES
  breakup-probability
  single-probability
  casual-probability
  intercourse-probability

  ;; SIMULATION VARIABLES
  warmup-time

  ;; POPULATION VARIABLES
  male-percentage
  average-semidegree
  rewiring-probability

  ;; VISUALIZATION VARIABLES
  ; gender visualization variables
  male-shape
  female-shape
  ; state visualization varibales
  susceptible-color
  incubating-color
  asymptomatic-color
  tracing-color
  recovered-color
  ; graph visualization variables
  potential-color
  already-traced-color
  traced-casual-color
  traced-stable-color
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
  time      ; useful to keep track of the infection times (e.g. incubation, recovery, ...)
  spring-x  ; useful for the spring layout
  spring-y  ; useful for the spring layout
]

links-own [
  potential ; "none" if the link is not present in the potential partners network otherwise the corresponding color
  past      ; "none" if the link is not present in the past partners network otherwise the corresponding color
  current   ; "none" if the link is not present in the current partners network otherwise the corresponding color
]

to setup
  clear-all                                                                                       ;
  set-globals                                                                                     ; assign values to global variables
  initialize-population                                                                           ; initialize turtles and link properties
  create-potential-partners-network                                                               ; create small-world potential partners networks
  ask n-of (initial-infected-percentage * population-size) turtles [ set color incubating-color ] ; infect a certain percentage of turtles
  repeat warmup-time [ simulate ]                                                                 ; warm-up the simulation to form couples
  display-network                                                                                 ; show the selected network
  repeat warmup-time [ simulate ]                                                                 ; warm-up the simulation to initially spread disease
  reset-ticks                                                                                     ;
end

to go
  if ticks < 365 * simulation-time [ simulate ]                                                   ; it simulates only a given number of days
  display-network                                                                                 ; but it always correctly displays the network
  tick                                                                                            ;
end

;; SETUP FUNCTIONS
to set-globals
  if model = "SIS" [ set actual-recovery-time 0 ]                                            ; if the compartmental model is "SIS", there is no recovery time
  if model = "SIR" [ set actual-recovery-time 365 * simulation-time + 1 ]                    ; if the compartmental model is "SIR", the recovery time is maximal
  if model = "SIRS" [ set actual-recovery-time recovery-time + 1 ]                           ; if the compartmental model is "SIRS", the recovery time is the given one
  set delay-rate 1 / average-notification-delay                                              ; probability for an traced individual to get the notification
  set screening-probability 1 / (365 * average-screening-time)                               ; probability for an indivudual to be tested spontaneously
  set breakup-probability 1 / 370                                                            ; probability for a couple to slipt up
  set single-probability 1 / 230                                                             ; probability for a single individual to be seeking a new relationship
  set casual-probability 0.25                                                                ; probability of seeking casual sex
  set intercourse-probability 1 / 7                                                          ; probability of having a sexual intercourse or to be seeking a casual relatinoship for core turtles
  set warmup-time 365                                                                        ; number of days used to form relationships and spread infection
  set male-percentage 0.5                                                                    ; probability for a node to be male
  set average-semidegree 20                                                                  ; half of the average number of potentials links including both sexes
  set rewiring-probability 0.25                                                              ; probability to have a friend outside the spatial neighborhood
  set male-shape "circle"                                                                    ; circle turtles  (male)
  set female-shape "square"                                                                  ; square turtles  (female)
  set susceptible-color 9.9                                                                  ; white turtles   (susceptible)
  set incubating-color 45                                                                    ; yellow turtles  (incubating)
  set asymptomatic-color 25                                                                  ; orangeg turtles (asymptomatic)
  set tracing-color 105                                                                      ; blue turtles    (tracing)
  set recovered-color 55                                                                     ; green turtles   (recovered)
  set potential-color 5                                                                      ; grey links      (potential partners)
  set already-traced-color 85                                                                ; cyan links      (past partners met before last visit)
  set traced-casual-color 15                                                                 ; yellow links    (past casual partners met after last visit)
  set traced-stable-color 45                                                                 ; red links       (past stable partners met after last visit)
  set casual-color 105                                                                       ; blue links      (current casual partners)
  set stable-color 55                                                                        ; green links     (current stable partners)
  set spring-factor sqrt population-size                                                     ; used to regulate the spring forces
  set zero-degree-factor 5                                                                   ; used to display zero-degree nodes
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
    if coin rewiring-probability [                                                           ; namely each link can be rewired according to the rewiring-probability
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
  spread-infection                                                                                                                           ; spreading the infection among relationships
  evolve-infection                                                                                                                           ; evolving the infections for certain statuses
  check-screenings                                                                                                                           ; checking spontaneous and traced screenings
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
  if-else even-sizes? [                                                                                                                      ;
    ask turtles [ set size node-size ]                                                                                                       ; finally. turtle sizes are chosen according to the switch
  ] [                                                                                                                                        ;
    let mean-degree mean [ count my-links with [ hidden? = false ] ] of turtles                                                              ;
    ask turtles [ set size node-size * (count my-links with [ hidden? = false ] + zero-degree-factor) / (mean-degree + zero-degree-factor) ] ;
  ]                                                                                                                                          ;
end

; RELATIONSHIP FUNCTIONS
to breakup-relationships
  ask links with [ current != "none" ] [                                                    ; for all the currently active relationships
    if current = casual-color or coin breakup-probability [                                 ; if the relationship is causal or if it is stable but it breaks up
      ask both-ends [ set status "Single" ]                                                 ; individuals are made single again
      set current "none"                                                                    ; and the relationship is removed
    ]                                                                                       ;
  ]                                                                                         ;
end

to update-status
  ask turtles with [ status = "Single" and core? ] [                                        ; for each single, core turtle
    if coin intercourse-probability [                                                       ; the turtle will be seeking a casual relationship according to intercourse-probability
      set status "Seek Casual"                                                              ;
    ]                                                                                       ;
  ]                                                                                         ;
  ask turtles with [ status = "Single" and not core? ] [                                    ; for each single, non-core turtle
    if coin single-probability [                                                            ; the turtle will decide to stop being single according to single-probability
      set status ifelse-value coin casual-probability [ "Seek Casual" ] [ "Seek Stable" ]   ; and to be seeking a casual or stable relationship according to casual-probability
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
          set past traced-casual-color                                                      ; - set "past" to traced-casual so that contact tracing can be active for that
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
          set past traced-stable-color                                                      ; - set "past" to traced-stable so that contact tracing can be active for that
          set current stable-color                                                          ; - set "current" to stable
          ask both-ends [ set status "Stable" ]                                             ; - set the sexual status of both the individuals to stable
        ]                                                                                   ;
      ]                                                                                     ;
    ]                                                                                       ;
  ]                                                                                         ;
end

;; SPREADING-FUCTIONS
to spread-infection
  ask links with [ current != "none" and any? both-ends with [ is-infected color ] ] [      ; for each active relationship involving at least one infected individual
    if current = casual-color or coin intercourse-probability [                             ; if the relationship is casual or if it is stable but the couple is having a sexual intercourse
      ask both-ends with [ color = susceptible-color ] [                                    ; we get only the susceptibles (if any), so that other infected or recovered people do not catch the infection
        if coin infection-spread-probability [                                              ; and according to the spreading probability
          set color incubating-color                                                        ; the individual starts incubating the infection
          set time incubation-time                                                          ; for a given time
        ]                                                                                   ;
      ]                                                                                     ;
    ]                                                                                       ;
  ]                                                                                         ;
end

to evolve-infection
  ask turtles with [ color = recovered-color ] [                                            ; for each recovered individual
    if-else time > 0 [                                                                      ; if the recovery time has expired
      set time time - 1                                                                     ; another tick passes
    ] [                                                                                     ; otherwise
      set color susceptible-color                                                           ; the individual becomes susceptible again
    ]                                                                                       ;
  ]                                                                                         ;
  ask turtles with [ color = incubating-color ] [                                           ; for each incubating individual
    if-else time > 0 [                                                                      ; if the incubation time has expired
      set time time - 1                                                                     ; another tick passes
    ] [                                                                                     ; otherwise
      if-else coin symptomatic-probability [ screen self ] [ set color asymptomatic-color ] ; the infection will become symptomatic (thus screened) with a given percentage, otherwise it will be asymptomatic
    ]                                                                                       ;
  ]                                                                                         ;
end

to check-screenings
  ask turtles with [ is-infected color ] [                                                  ; for each infected individual
    if coin screening-probability [ screen self ]                                           ; there is a certain probability for spontaeous screening
  ]                                                                                         ; (the probability exists for non infective individuals as well, but nothing will change so they are not considered)
  ask turtles with [ color = tracing-color ] [                                              ; for each individual who's trying to be traced
    if coin delay-rate [ screen self ]                                                      ; there is a certain probability for them to get the screening
  ]                                                                                         ; (this is used to take into accounts notification and visit delays)
end

to screen [ individual ]
  ask individual [                                                                          ; when an individual is subjected to a screening
    if is-infected color [                                                                  ; if it is infected
      set color recovered-color                                                             ; at first, it gets recovered (for simplification, we say that traced and recovered individuals will have protected sex)
      set time actual-recovery-time                                                         ; and the recovery will last for a given number of ticks
      ask my-links with [ past = traced-casual-color or past = traced-stable-color ] [      ; then, for each past partner that is being traced:
        if current = stable-color                                                           ; - and it will be notified if in a current relationship
        or (past = traced-casual-color and coin casual-tracing-probability)                 ;   or if in a past casual relationship according to the given probability
        or (past = traced-stable-color and coin stable-tracing-probability) [               ;   or if in a past stable relationship according to the given probability
          ask both-ends with [ is-infected color ] [ set color tracing-color ]              ; - we set it to tracing if it is not already in the recovery state
        ]                                                                                   ;
        set past already-traced-color                                                       ; - the partner will not be traced during next screenings
      ]                                                                                     ;
    ]                                                                                       ;
  ]                                                                                         ;
end

;; UTIL FUNCTIONS
to-report coin [ p ]
  report random-float 1 < p                              ; simulates a sample from a Bernoulli random variable with probability of success equals to p
end

to-report is-infected [ c ]
  report c != susceptible-color and c != recovered-color ; infected individuals are the incubating, asymptomatic and tracing one, as recovered individuals are supposed have protected or no intercourse
end
@#$#@#$#@
GRAPHICS-WINDOW
259
10
858
610
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
-295
295
-295
295
1
1
0
ticks
30.0

SLIDER
5
10
251
43
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
5
254
84
287
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
175
254
253
287
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
5
328
120
373
partners-network
partners-network
"Potential" "Past" "Current"
2

SWITCH
5
291
121
324
even-sizes?
even-sizes?
1
1
-1000

CHOOSER
125
328
253
373
layout
layout
"Circle" "Random" "Spring" "Stop"
1

SLIDER
5
465
252
498
casual-tracing-probability
casual-tracing-probability
0
1
0.3
0.01
1
NIL
HORIZONTAL

SLIDER
5
502
252
535
stable-tracing-probability
stable-tracing-probability
0
1
0.8
0.01
1
NIL
HORIZONTAL

SLIDER
5
576
253
609
average-screening-time
average-screening-time
1.0
10
5.0
0.1
1
years
HORIZONTAL

SLIDER
125
291
253
324
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
1167
10
1493
178
Sexual Status
days
%
0.0
0.0
0.0
10.0
true
true
"set-plot-x-range 0 365 * simulation-time" ""
PENS
"single" 1.0 0 -16777216 true "" "if ticks < 365 * simulation-time [\n  plot count turtles with [ status = \"Single\" ] / count turtles * 100\n]"
"s-casual" 1.0 0 -2064490 true "" "if ticks < 365 * simulation-time [\n  plot count turtles with [ status = \"Seek Casual\" ] / count turtles * 100\n]"
"s-stable" 1.0 0 -11221820 true "" "if ticks < 365 * simulation-time [\n  plot count turtles with [ status = \"Seek Stable\" ] / count turtles * 100\n]"
"casual" 1.0 0 -13345367 true "" "if ticks < 365 * simulation-time [\n  plot count turtles with [ status = \"Casual\" ] / count turtles * 100\n]"
"stable" 1.0 0 -10899396 true "" "if ticks < 365 * simulation-time [\n  plot count turtles with [ status = \"Stable\" ] / count turtles * 100\n]"

BUTTON
88
254
170
287
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
865
10
1163
130
Number Of Sexual Partners Distribution
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
"default" 1.0 1 -16777216 true "" "plot-pen-reset\nlet max-degree max [count my-links with [ past != \"none\" ] ] of turtles\nlet min-degree min [count my-links with [ past != \"none\" ] ] of turtles\nlet values [count my-links with [ past != \"none\" ] ] of turtles\nset-plot-x-range min-degree (max-degree + 1)\nset-plot-y-range 0 max values\nhistogram values"

SLIDER
5
391
252
424
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
865
134
1013
179
Non-Core Sexual Partners
mean [ count my-links with [ past != \"none\" ] ] of turtles with [ not core? ]
2
1
11

MONITOR
1017
134
1163
179
Core Sexual Partners
mean [ count my-links with [ past != \"none\" ] ] of turtles with [ core? ]
2
1
11

PLOT
864
405
1494
610
Overall Infection Spread
days
%
0.0
10.0
0.0
10.0
true
true
"set-plot-x-range 0 365 * simulation-time" ""
PENS
"tracing" 1.0 1 -13345367 true "" "if ticks < 365 * simulation-time [\n  let total count turtles\n  let val count turtles with [ color = tracing-color or color = asymptomatic-color or color = incubating-color ]\n  plot val / total * 100\n]"
"asymptomatic" 1.0 1 -955883 true "" "if ticks < 365 * simulation-time [\n  let total count turtles\n  let val count turtles with [ color = asymptomatic-color or color = incubating-color ]\n  plot val / total * 100\n]"
"incubating" 1.0 1 -1184463 true "" "if ticks < 365 * simulation-time [\n  let total count turtles\n  let val count turtles with [ color = incubating-color ]\n  plot val / total * 100\n]"

SLIDER
5
539
252
572
average-notification-delay
average-notification-delay
1
120
7.0
1
1
days
HORIZONTAL

PLOT
864
185
1495
399
Core Percentages
days
%
0.0
10.0
0.0
10.0
true
true
"set-plot-x-range 0 365 * simulation-time" ""
PENS
"not infected" 1.0 0 -16777216 true "" "if ticks < 365 * simulation-time [\n  let total count turtles with [ not is-infected color ]\n  let core count turtles with [ not is-infected color and core? ]\n  plot ifelse-value total > 0 [ core / total * 100 ] [ 0 ]\n]"
"infected" 1.0 0 -2674135 true "" "if ticks < 365 * simulation-time [\n  let total count turtles with [ is-infected color ]\n  let core count turtles with [ is-infected color and core? ]\n  plot ifelse-value total > 0 [ core / total * 100 ] [ 0 ]\n]"

SLIDER
5
82
251
115
initial-infected-percentage
initial-infected-percentage
0
1
0.05
0.01
1
NIL
HORIZONTAL

SLIDER
5
119
251
152
symptomatic-probability
symptomatic-probability
0
1
0.3
0.01
1
NIL
HORIZONTAL

SLIDER
5
155
251
188
incubation-time
incubation-time
0
180
14.0
1
1
days
HORIZONTAL

SLIDER
101
203
251
236
recovery-time
recovery-time
1
180
14.0
1
1
days
HORIZONTAL

CHOOSER
5
192
97
237
model
model
"SIS" "SIR" "SIRS"
2

SLIDER
5
46
251
79
simulation-time
simulation-time
1
30
10.0
0.5
1
years
HORIZONTAL

SLIDER
5
428
252
461
infection-spread-probability
infection-spread-probability
0
1
0.4
0.01
1
NIL
HORIZONTAL

@#$#@#$#@
# STI Spread Simulator

## WHAT IS IT?

This model simulates the spread of a Sexually Transmitted Infection (STI) among a sexually active, heterosexual population of youth aged 15-24. It therefore illustrates how much certain behavioural factors and non-pharmaceutical interventions (NPIs) can contain the spread of the infection.

The user can define some initial parameters related to the population and to the infection itself, such as the percentage of symptomatic cases, the incubation and the recovery time (if present), and the control the effectiveness of six parameters related to the effectiveness of NPIs in order to see how these changes affect the progression of the infection among the population.

For a deeper understanding of the model, a detailed report is available for consultation at: https://github.com/giuluck/STI-Spread-Simulator.

## HOW IT WORKS

Each node in the simulation represents an individual. Half of the individuals are male, the other half is female. Also, a certain percentage of "core" individuals can be chosen, where "core" individuals are those having casual relationships only.

An initial "potential partners network" is created using the Watts-Strogatz formulation to represent small-world effects when choosing a stable partner, and as heterosexual couples only are considered for simplicity, same-sex links are removed. However, casual sex is taken into account, and casual couples can be formed among non-neighbours as well.

The simulation is then warmed-up for one year to form relationships. Then, a given percentage of nodes is infected and the simulation is warmed-up again for one year to let the endemic development of the infection emerge.

At this point, the simulation runs for another given number of years. It is possible to see the development of the simulation thanks to the monitors and the plots, while on the central area the three networks (potential partners, past partners, and current partners) can be chosen and inspected as the time passes.

## HOW TO USE IT

On the upper left area there are some controls for the population and infection variables, which should be fixed to simulate the spread of a certain STI in a given population. They are:
- POPULATION-SIZE: the number of youths involved in the simulation.
- SIMULATION-TIME: the number of years to be simulated (after the first two years for warm-up)
- INITIAL-INFECTED-PERCENTAGE: the percentage of infected individuals before the second round of warm-up
- SYNPTOMATIC PROBABILITY: the probability that an incubating individual will show symptoms
- INCUBATION-TIME: the time between the infection and the eventual appearance of symptoms
- RECOVERY-TIME: the time between being testes/cured and becoming susceptible again (this parameter has a meaning only if the "SIRS" model is chosen, otherwise the recovery time will be set to zero days in case of "SIS" model or an infinite number of days in case of "SIR" model)

Once these parameters are set, the SETUP button creates the population and warms-up the simulation. At that point, it is possible either to simulate a single day with the button GO-ONCE or to let the simulation run until the end with the button GO. During the simulation, it is possible to change some settings using the controls right under the three buttons. In particular:
- EVEN-SIZES?: decides whether all the nodes have the same size or nodes with higher degree have a greater size
- NODE-SIZE: decides the average node size
- PARTNERS-NETWORK: decides which of the three networks (potential, past or current) is visualised
- LAYOUT: decides how to layout the network

On the right area, some monitors and plots are displayed to understand the evolution of the model. On top, a plot shows the distribution of the number of past partners for the population; this should be a bimodal distribution due to the different behaviour of "core" and "non-core" members, which is also noticeable from the two monitors under the plot showing the average number of sexual partners for the two categories. Near that, there is a small plot indicating the percentage of individuals in a certain sexual status (single, seeking casual, seeking stable, casual, or stable) over the time. Below that, the two main plots are displayed: the upper one indicates how much of the percentage of infected (incubating + asymptomatic + tracing) and non-infected (susceptibles + recovered) individuals are part of the "core" group with respect to each category, while the lower one indicates the percentage of infected individuals with respect to the whole population divided into the three infected categories.

Finally, on the lower left area, there are the six control parameters used to study the effects of NPIs on the spread of the infection. They are:
- CORE-GROUP-PERCENTAGE: the percentage of "core" individuals in the whole population
- INFECTION-SPREAD-PROBABILITY: the probability that an infected individual passes the infection to a susceptible one during a sexual intercourse (this may take into account the actual load of the infection as well as the usage and effectiveness of protection methods such as condoms or other barrier methods)
- CASUAL-TRACING-PROBABILITY: the probability that an old casual partner is notified and undergoes a screening
- STABLE-TRACING-PROBABILITY: the probability that an old stable partner is notified and undergoes a screening
- AVERAGE-NOTIFICATION-DELAY: the average delay between the moment an individual's old partner has tested positive for the STI and the individual themselves is notified (follows a geometrical distribution)
- AVERAGE-SCREENING-TIME: the average number of years passing between two spontaneous screenings (follows a geometrical distribution)

## THINGS TO NOTICE

The experiment carried out in the report simulates the spread of chlamydia. To do that, a population of 500 individuals is set and the simulation is run for 10 years. The initial infected percentage is set to 5% (on par with the average percentage of chlamydia infections among youth) and the symptomatic percentage is set to 30%, as chlamydia remains silent in seven cases out of ten. The incubation time is set to 14 days (this is the reported average, varying from 7 to 21 days in general) and the SIRS model is selected, with a recovery time of 14 days in order to consider both the 7 days period (on average) to get the results from the screening and the 7 days period of medications, in which individuals are assumed to have fully protected sex or no sex at all.

## THINGS TO TRY

Run a number of experiments with the GO button to find out the effects of different variables on the spread of infection. Remember to always press SETUP before of each run in order to warm it up.

## EXTENDING THE MODEL

This model was implemented with some simplifications, which may be overcome more or less easily depending on the cases.

First of all, incubation and recovery time are fixed for each subject, and other random variables often follow a geometrical or Bernoulli distribution without any prior knowledge. For instance, when it comes to notify an old partner, the only distinction made is between old casual relationships and old stable ones, but in real life some other aspects are take into account, such as whether the partners were friends aside from the relationship or not, how many sexual encounters they had and how much time has passed. Also, it is reasonable to thinks that more "familiar" ex-partners will be notified sooner than more "stranger" ones.

Another huge simplification made is that heterosexual relationships only are considered. Homo/bisexuality could introduce a higher level of variability in the model, also because different sex practice, with different danger, can be carried out depending on the sex of the people involved. Moreover, condom usage and similar is considered to be the same among all the population, while it is reasoable to think that some people are more likely to always use protections, while other are not.

Finally, no cheating phenomena is included, and relationships are always considered to be serially monogamous and sexually active. This is not always the case, especially for youth. Indeed, there may be some relationship which does not involve sex at all, while some others can be characterised by sexual non-exclusivity or cheating.
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

circle-core
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

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
