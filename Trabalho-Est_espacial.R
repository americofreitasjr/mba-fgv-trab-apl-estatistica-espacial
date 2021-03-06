#Carregando o pacote rgdal, maptools e dplyr
library(rgdal)
library(maptools)
library(dplyr)
library(spatstat)
library(MASS)
library(readr)
#Importando o shapefile de Houston
Mapa_Houston <- readOGR("Houston_City_Limit/Houston_City_Limit.shp")

#Carregando o pacote readr
library(readr)

#Importando o arquivo com as localizações ocorrências de crimes na cidade de Houston.

Base_Houston = read_csv("Base Houston.csv")

#Carregando o pacote spatstat
library(spatstat)

#Definindo o shapefile como uma janela onde os pontos serao plotados
#necessario para o uso do pacote spatstat
Houston <- as.owin(Mapa_Houston)

#Plotando o shapefile
plot(Houston)

#Criando o padrao de pontos a ser plotado
Houston_ppp = ppp(Base_Houston$lon, Base_Houston$lat, window=Houston)

#Plotando as localizacoes dos delitos
par(mar=c(0.5,0.5,1.5,0.5))
plot(Houston_ppp, pch=21, cex=0.9, bg="blue", main="Ocorrencias de crimes em Houston")

#Estimando o efeito de primeira ordem (intensidade) usando diferentes kernels
Houston.q = density.ppp(x = Houston_ppp, sigma=0.05, kernel="quartic")
Houston.g = density.ppp(x = Houston_ppp, sigma=0.05, kernel="gaussian")
Houston.e = density.ppp(x = Houston_ppp, sigma=0.05, kernel="epanechnikov")
 
##density.ppp - calcula a funcao de intensidade de acordo com o kernel escolhido
#Argumentos:
#x - objeto da classe ppp
#sigma - é o valor do raio (tau na expressao dos slides)
#kernel - o kernel que deseja-se usar


#-------------------------APRESENTAÇÃO DO ESPAÇO------------------------------------


#Plotando os dados e as funcoes intensidades estimadas pelas diversas funcoes kernel
par(mfrow=c(2,2))
plot(Houston_ppp, pch=21, cex=0.9, bg="blue", main="Ocorrencias", cex.main=0.5)
plot(Houston.q, main="Kernel Quartico", cex.main=0.5)
plot(Houston.g, main="Kernel Normal")
plot(Houston.e, main="Kernel Epanechnikov")
par(mfrow=c(1,1))


#-------------------------------------------------------------------------------
#------------------------FUNÇÃO DE PRMEIRA ORDEM--------------------------------
#-------------------------------------------------------------------------------

#Funcao que estima o raio por meio de validacao cruzada 
raio.est = bw.diggle(Houston_ppp)
raio.est
plot (raio.est)

#Plotaremos o mapa com o raio estimado e Kernel Gaussian, esse Estimador é um método
# de interpolação que mede a intensidade de ocorrências do processo em toda
#região de estudo. Assim criamos as primeiras impressões sobre o padrão dos pontos.
#plot(density.ppp(Houston_ppp, sigma=raio.est, kernel="gaussian",cex.main=0.002))

plot(density.ppp(Houston_ppp, sigma=raio.est, kernel="gaussian"), main="Kernel Gaussiano com Sigma=0.002992444 ", cex.main=0.002)
#O mapa com raio ótimo nos permite ter a intuição de que há agrupamento em  
#determinados pontos do mapa. Para confirmarmos ou não esse sentimento ainda teremos
#que realizar mais análizes.


#---------------------------------------------------------------------------------
#--------------------------FUNÇÃO DE SEGUNDA ORDEM--------------------------------
#---------------------------------------------------------------------------------

#Após observarmos os padrões dos pontos na Função de primeira ordem, denotaremos um 
#processo pontual com função de intensidade de Segunda Ordem, onde analisaremos a
#distância do vizinho mais próximo


#----------------------------------------------------------------------------------
#---------------------Testando completa aleatoriedade espacial(CSR)----------------
#----------------------------------------------------------------------------------

#Método da quadratura
cont = quadratcount(X = Houston_ppp, nx = 5, ny = 5)

##quadratcount - dividi uma janela em retangulos e conta o numero de pontos em cada
#um deles
#Argumentos:
#X - objeto do tipo ppp
#nx - numero de particoes no eixo x
#nx - numero de particoes no eixo y

#Visualizando as contagens em cada celula
cont

#Plotando as contagens
par(mar=c(0.5,0.5,1.5,1))
plot(cont, main="Teste CSR com Método da Quadratura")

##quadrat.test - realiza um teste de qui-quadrado para testar completa aleatoriedade 
#espacial
teste = quadrat.test(X = Houston_ppp, nx = 3, ny = 4)
#Argumentos:
#X - objeto do tipo ppp
#nx - numero de particoes no eixo x
#nx - numero de particoes no eixo y

#Visualizando o resultado do teste
teste

#Plotando o teste
plot(teste, main="Teste CSR com Método Qui-quadrado")

#------------------Testes de hipoteses Clarkevans e Hospkel-------------------------
clarkevans.test(Houston_ppp)

hopskel.test(Houston_ppp, alternative="clustered")

# Nos 3 testes o p-Value foi 2.2e-16, que é menor que o nível de significância
#de 0.05. Os testes sugerem que podemos rejeitar a hipótese nula 
#de completa aleatoriedade espacial. 


#-------------------------------FUNÇÕES K,G e F-----------------------------------

#Estimando a funcao G
Houston.G = Gest(Houston_ppp)

#Gest - estima a funcao de distribuicao G de um padrao de pontos
#Argumento
#X - um objeto da classe ppp

#Estimando a funcao K (alto custo computacional)
####### Houston.K = Kest(Houston_ppp)

#Kest - estima a funcao K de Ripley de um padrao de pontos
#Argumento
#X - um objeto da classe ppp

#Estimando a funcao F
Houston.F = Fest(Houston_ppp)

#Fest - estima a funcao F de um padrao de pontos
#Argumento
#X - um objeto da classe ppp

#Plotando as funcoes G, K e F
par(mfrow = c(1,2))
par(mar=c(2.5,2.5,1.5,.5))
plot(Houston.G, main="Funcao G")
#plot(Houston.K, main="Funcao K")
plot(Houston.F, main="Funcao F")
par(mfrow = c(1,2))

# Na Função G a curva estimada dos dados esta oposta superiormente a curva de Poisson
# indicando agrupamento.
# Na Função F a curva estimada está abaixo da curva de Poisson, na qual também indica 
# agrupameto

#------------------------------------Envelopamento----------------------------

#envelopado
Houston_envelop_G = envelope(Houston_ppp,fun = Gest, nsim=20)
plot(Houston_envelop_G)
#A curva estimada está fora do envelope, indicando agrupamento

Houston_envelop_F = envelope(Houston_ppp,fun = Fest, nsim=20)
plot(Houston_envelop_F)
#A curva estimada está fora do envelope, indicando agrupamento

#Houston_envelop_K = envelope(Houston_ppp,fun = Kest, nsim=20) #(alto custo computacional)
#plot(Houston_envelop)


#-------------------------------------------------------------------------------------#
# ------------------ Ajustando o processo de Poisson homogeneo----------------------#
#-------------------------------------------------------------------------------------#

# Para estimarmos a aleatoriedade dos pontos usaremos o modelo mais trivial,
#o Processo de Poisson homogêneo.

#Ajustando o processo de Poisson homogeneo
ajuste1 = ppm(Q = Houston_ppp ~ 1)

##ppm - Ajusta o processo de Poisson
#Argumentos:
#Q - Objeto ppp ~ 1 (ajusta o homogêneo)

#Visualizando o modelo ajustado
ajuste1

#o modelo basicamente nos diz (Ztest)que as variaveis X e Y são relevantes(***)



#-------------------------------------------------------------------------------------#
# ------------------ Ajustando o processo de Poisson nao-homogeneo   -----------------#
#-------------------------------------------------------------------------------------#

#Ajustando um processo de Poisson nao-homogeneo que e log-linear nas coordenadas cartesianas
ajuste2 = ppm(Q = Houston_ppp ~ x + y)

#Visualizando o modelo ajustado
ajuste2
#Plotando a funcao de intensidade ajustada em funcao das coordenadas x e y
par(mar=c(1.5,1.5,1.5,1))
plot(ajuste2, how = "image", se = FALSE, pause = FALSE, axes = TRUE, main="Função de Intensidade Ajustada")

#Plotando o erro padrao da funcao de intensidade ajustada pelo modelo
plot(ajuste2, how = "image", se = TRUE, pause = FALSE, main="Erro Padrão da Função de Intensidade Ajustada")

#Calculando o efeito de uma unica variavel no modelo
efeito.1vari = effectfun(model = ajuste2, covname = "x", y = 40.7)

#Plotando o efeito de uma unica covariavel no modelo
par(mar=c(2,2,2,1))
plot(efeito.1vari , main = "Efeito de uma única variável")

##effectfun - realiza um teste de qui-quadrado para testar completa aleatoriedade espacial
#Argumentos:
#model - modelo ajustado
#covname - nome da variavel que quer avaliar o efeito
#y - foi preciso colocar um valor de y, pois estamos desejando ver o efeito em x

#--------------------------------------------------------------------------------------------#
#Ajustando um processo de Poisson nao-homogeneo com covariaveis diferentes de coordenadas  #
#--------------------------------------------------------------------------------------------#

#Gera um objeto da classe quad
particao <- quadscheme(Houston_ppp)

#Visualizando o obejto da classe quad
par(mar=c(0.5,0.5,1.5,0.5))
plot(particao)

#Extraindo as coordenadas do grid criado
x.par <- x.quad(particao)
y.par <- y.quad(particao)

#Visualizando as coordenadas
x.par[1:5]
y.par[1:5]

#Importando os dados complementares (observados nos pontos do grid)
#Estou assumindo que os dados se encontram na ordenacao das coordenadas de x.par e y.par
base.comp = read_csv("complementares todos crimes.csv")
Delegacia = base.comp$delegacia #Se ha delegacias próximas aos delitos
Investimento = base.comp$investimento #investimento empregue naquela regiao
Armas= base.comp$armas #Armas registradas

#Ajustando um processo de Poisson nao-homogeneo que e log-linear nas coordenadas cartesianas e 
#considera as covariaveis numero de armas apreebdidas no mes passado e se houve blitz policial no ultimo mes
ajuste3 = ppm(Q = Houston_ppp ~ x + y + D + I  , covariates = data.frame(D = Delegacia, I = Investimento))

#Visualizando o modelo ajustado
ajuste3
#Aparentemente as duas variaveis adicionais, não são significativas nesse modelo.

#Calculando o risco relativo s_1 versus s_2

#s_1
x.par[100]
y.par[100]

#s_2
x.par[500]
y.par[500]

plot(Houston_ppp, pch=21, cex=0.3, bg="blue", main="Risco Relativo s_1 x s_2")
points(x.par[100],y.par[100],col="green", cex=3.9)
points(x.par[700],y.par[700],col="red", cex=3.9)

RR.num = (-127.30 + 3.54 * x.par[100] + 4.96 * y.par[100] + 0.02 * Delegacia[100] + 0.35 * Investimento[100])
RR.den = (-127.30 + 3.54 * x.par[700] + 4.96 * y.par[700] + 0.02 * Delegacia[700] + 0.35 * Investimento[700])

RR = RR.num/RR.den

RR
#Há um aumento no risco quando comparado a região s_1 e a região s_2 em torno 
#de 99%.

#Como escolher o melhor modelo
AIC(ajuste1)
AIC(ajuste2)
AIC(ajuste3)
#O modelo preferido é aquele com menor AIC = ajuste1
#Funcao que automatiza a selecao dos modelos
stepAIC(ajuste1)

#O Criterio AIC indica o modelo que contem as coordenadas x e y e a variavel numero 
#de armas registradas
ajuste.final = ppm(Q = Houston_ppp ~ x + y+ A, covariates = data.frame(A=Armas))

ajuste.final

