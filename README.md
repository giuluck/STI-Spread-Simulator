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