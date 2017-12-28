--
-- PostgreSQL database cluster dump
--

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Drop databases
--

--DROP DATABASE nick_dev;




--
-- Drop roles
--

--DROP ROLE postgres;


--
-- Roles
--

--CREATE ROLE postgres;
ALTER ROLE postgres WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS PASSWORD 'md5a3556571e93b0d20722ba62be61e8c2d';






--
-- Database creation
--

CREATE DATABASE nick_dev WITH TEMPLATE = template0 OWNER = postgres CONNECTION LIMIT = 25;
REVOKE CONNECT,TEMPORARY ON DATABASE template1 FROM PUBLIC;
GRANT CONNECT ON DATABASE template1 TO PUBLIC;


\connect nick_dev

SET default_transaction_read_only = off;

--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.5
-- Dumped by pg_dump version 9.6.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: fun_atualiza_rating_trigger(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fun_atualiza_rating_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

DECLARE
	vnSeqErro   	        integer;
  vnSeqSugestao	        integer;
    
BEGIN

  SELECT SE.SEQ_ERRO
       , SE.SEQ_SUGESTAO       
       INTO
       	vnSeqErro 
      , vnSeqSugestao
    FROM SUGESTAO_ERRO SE
  WHERE SE.SEQ_SUGESTAO_ERRO = new.seq_sugestao_erro;
    
    IF new.solucionado = 'S' THEN
     PERFORM fun_atualiza_relevancia(vnSeqErro, vnSeqSugestao);
     END IF;
    
  INSERT INTO PAMONHA (NOME) 
  VALUES (CONCAT(NOW(), ' ', 'iNSERÇÃO; ', ' Erro: ', vnSeqErro, ' Sugestão: ', vnSeqSugestao ));
  RETURN NEW;
  
END;

$$;


ALTER FUNCTION public.fun_atualiza_rating_trigger() OWNER TO postgres;

--
-- Name: fun_atualiza_relevancia(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fun_atualiza_relevancia(psseqerro integer, psseqsugestao integer) RETURNS void
    LANGUAGE plpgsql
    AS $$DECLARE
	vnErroMaximo   	        integer;
    vnErroMinimo			integer;
    vnErroCount  			integer;
    vnSeqAplicacao			integer;
    vnSugestaoMaximo   	    integer;
    vnSugestaoMinimo		integer;
    vnSugestaoCount 		integer;
  
   
BEGIN

------------------------------------------------------------------  
-- ATUALIZAÇÃO DO ERRO
------------------------------------------------------------------  
     -- ATUALIZA OCORRÊNCIA DO ERRO
     UPDATE ERRO
        SET OCORRENCIA = OCORRENCIA + 1
        WHERE SEQ_ERRO = psSeqErro;
        
            
     -- SELECIONA A APLICAÇÃO 
        SELECT ERRO.SEQ_APLICACAO
          INTO vnSeqAplicacao
          FROM ERRO
         WHERE ERRO.SEQ_ERRO = psSeqErro ;    
         
    -- SELECIONA A QUANTIDADE DE ERROS PARA A APLICAÇÃO
        SELECT COUNT(ERRO.SEQ_ERRO)
          INTO vnErroCount
          FROM ERRO
         WHERE ERRO.SEQ_APLICACAO = vnSeqAplicacao ;   
        
    -- SELECIONA O VALOR MAXIMO 
        SELECT MAX(OCORRENCIA)
          INTO vnErroMaximo
          FROM ERRO
         WHERE ERRO.SEQ_APLICACAO = vnSeqAplicacao ;   
         
    -- SELECIONA O VALOR MINIMO
        SELECT MIN(OCORRENCIA)
          INTO vnErroMinimo
          FROM ERRO
         WHERE ERRO.SEQ_APLICACAO = vnSeqAplicacao ; 
  
    -- CALCULO RELEVÂNCIA  
     ---- CASO 1: APENAS 1 ERRO CADASTRADO
     IF vnErroCount = 1 THEN
          UPDATE ERRO
             SET RELEVANCIA = 1
           WHERE ERRO.SEQ_APLICACAO = vnSeqAplicacao;
     
     ELSE
     ---- CASO 2: MAIS DE UM ERRO CADASTRADO, MAS COM OCORRÊNCIAS IGUAIS
    	  IF vnErroMaximo = vnErroMinimo THEN
               UPDATE ERRO
            	  SET RELEVANCIA = 0
                WHERE ERRO.SEQ_APLICACAO = vnSeqAplicacao;
    
     
     ---- CASO 3:MAIS DE UM ERRO CADASTRADO, MAS COM OCORRÊNCIAS DIFERENTES
    	  ELSE
               UPDATE ERRO
            	  SET RELEVANCIA =  cast((OCORRENCIA - vnErroMinimo) AS real)/(vnErroMaximo - vnErroMinimo)
                WHERE ERRO.SEQ_APLICACAO = vnSeqAplicacao;
          END IF;
      END IF;


-----------------------------------------------------------------  
-- ATUALIZAÇÃO DA SUGESTAO
------------------------------------------------------------------  
	-- ATUALIZA OCORRÊNCIA DA SUGESTAO
     UPDATE SUGESTAO_ERRO
        SET OCORRENCIA = OCORRENCIA + 1
        WHERE SEQ_SUGESTAO = psSeqSugestao
        AND	  SEQ_ERRO = psSeqErro;
        
        
    -- SELECIONA O VALOR MAXIMO 
        SELECT MAX(OCORRENCIA)
          INTO  vnSugestaoMaximo 
          FROM SUGESTAO_ERRO
         WHERE SEQ_ERRO = psSeqErro ;   
         
    -- SELECIONA O VALOR MINIMO
        SELECT MIN(OCORRENCIA)
          INTO  vnSugestaoMinimo
          FROM SUGESTAO_ERRO
         WHERE SEQ_ERRO = psSeqErro ;  
         
     -- SELECIONA A QUANTIDADE DE SUGESTÕES
        SELECT COUNT(SUGESTAO_ERRO.SEQ_SUGESTAO)
          INTO vnSugestaoCount
          FROM SUGESTAO_ERRO
         WHERE SEQ_ERRO = psSeqErro ;         
 
     -- CALCULO RELEVÂNCIA  
     ---- CASO 1: APENAS 1 SUGESTÃO CADASTRADA 
     IF vnSugestaoCount = 1 THEN
     
          UPDATE SUGESTAO_ERRO
             SET RELEVANCIA = 1
           WHERE SUGESTAO_ERRO.SEQ_ERRO = psSeqErro;
     
     ELSE
     ---- CASO 2: MAIS DE UMA SUGESTAO CADASTRADA, MAS COM OCORRÊNCIAS IGUAIS
    	  IF vnSugestaoMaximo = vnSugestaoMinimo THEN
               UPDATE SUGESTAO_ERRO
                  SET RELEVANCIA = 0
                WHERE SUGESTAO_ERRO.SEQ_ERRO = psSeqErro;
     ---- CASO 3:MAIS DE UM ERRO CADASTRADO, MAS COM OCORRÊNCIAS DIFERENTES
    	  ELSE
                 UPDATE SUGESTAO_ERRO
                    SET RELEVANCIA =  cast((OCORRENCIA - vnSugestaoMinimo) AS real)/(vnSugestaoMaximo - vnSugestaoMinimo)
                  WHERE SEQ_ERRO = psSeqErro;
          END IF;
      END IF;    
END;

$$;


ALTER FUNCTION public.fun_atualiza_relevancia(psseqerro integer, psseqsugestao integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: anexo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE anexo (
    seq_anexo integer NOT NULL,
    descricao character varying(40) NOT NULL,
    anexo text NOT NULL,
    seq_erro integer NOT NULL
);


ALTER TABLE anexo OWNER TO postgres;

--
-- Name: TABLE anexo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE anexo IS 'Tabela criada para armazenar os anexos que o cliente adicionar ao erro, quando este for direcionado à consultora.';


--
-- Name: COLUMN anexo.descricao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN anexo.descricao IS 'Coluna texto que identifica de maneira sucinta o anexo.';


--
-- Name: COLUMN anexo.anexo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN anexo.anexo IS 'Anexo, podendo ser qualquer tipo de arquivo ou imagem.';


--
-- Name: anexo_seq_anexo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE anexo_seq_anexo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE anexo_seq_anexo_seq OWNER TO postgres;

--
-- Name: anexo_seq_anexo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE anexo_seq_anexo_seq OWNED BY anexo.seq_anexo;


--
-- Name: aplicacao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE aplicacao (
    seq_aplicacao integer NOT NULL,
    aplicacao character varying(12) NOT NULL,
    descricao character varying(100) NOT NULL,
    seq_modulo integer NOT NULL
);


ALTER TABLE aplicacao OWNER TO postgres;

--
-- Name: TABLE aplicacao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE aplicacao IS 'Tabela criada para armazenar as informações referente as aplicações desenvolvidas pela empresa e que compõem os módulos. ';


--
-- Name: COLUMN aplicacao.aplicacao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN aplicacao.aplicacao IS 'Coluna texto que identifica o código da aplicação.(Informação obtida da GE_APLICACAO)';


--
-- Name: COLUMN aplicacao.descricao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN aplicacao.descricao IS 'Nome completo da aplicação. (Informação obtida da GE_APLICACAO)';


--
-- Name: aplicacao_seq_aplicacao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE aplicacao_seq_aplicacao_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE aplicacao_seq_aplicacao_seq OWNER TO postgres;

--
-- Name: aplicacao_seq_aplicacao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE aplicacao_seq_aplicacao_seq OWNED BY aplicacao.seq_aplicacao;


--
-- Name: erro; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE erro (
    seq_erro integer NOT NULL,
    titulo character varying(160) NOT NULL,
    descricao character varying(4000) NOT NULL,
    tags character varying(100) NOT NULL,
    ocorrencia integer DEFAULT 0,
    relevancia real DEFAULT 0,
    detalhes text NOT NULL,
    seq_aplicacao integer NOT NULL
);


ALTER TABLE erro OWNER TO postgres;

--
-- Name: TABLE erro; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE erro IS 'Tabela criada para armazenar os erros conhecidos informados pelos clientes, quando direcionado à consultora. ';


--
-- Name: COLUMN erro.titulo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN erro.titulo IS 'Coluna texto com descrição sucinta do erro.';


--
-- Name: COLUMN erro.descricao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN erro.descricao IS 'Coluna texto com a descrição detalhada do erro para que seja possível entendê-lo.';


--
-- Name: COLUMN erro.tags; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN erro.tags IS 'Coluna texto com palavras chave para o sistema de busca do erro.';


--
-- Name: COLUMN erro.ocorrencia; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN erro.ocorrencia IS 'Coluna numérica (Inteira) que funciona como contador para todas as vezes que o cliente acessar esse erro e informar que o problema foi solucionado.';


--
-- Name: COLUMN erro.relevancia; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN erro.relevancia IS 'Coluna numérica (decimal) que armazena o valor normalizado do erro, em relação ao demais erros da mesma aplicação.';


--
-- Name: COLUMN erro.detalhes; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN erro.detalhes IS 'Coluna para armazenar imagens ou outros tipos de documentos que disponibilizados pelos empresa, ajudem o cliente a entender o erro.';


--
-- Name: erro_seq_erro_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE erro_seq_erro_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE erro_seq_erro_seq OWNER TO postgres;

--
-- Name: erro_seq_erro_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE erro_seq_erro_seq OWNED BY erro.seq_erro;


--
-- Name: modulo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE modulo (
    seq_modulo integer NOT NULL,
    modulo character varying(12) NOT NULL,
    sigla character varying(5) NOT NULL,
    descricao character varying(40) NOT NULL
);


ALTER TABLE modulo OWNER TO postgres;

--
-- Name: TABLE modulo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE modulo IS 'Tabela criada para armazenar as informações referente aos módulos desenvolvidos pela empresa e que compõem as atualizações. ';


--
-- Name: COLUMN modulo.modulo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN modulo.modulo IS 'Coluna texto que identifica o código do módulo.(Informação obtida da GE_MODULO)';


--
-- Name: COLUMN modulo.sigla; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN modulo.sigla IS 'Informação obtida da GE_MODULO.SIGLAMODULO.';


--
-- Name: COLUMN modulo.descricao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN modulo.descricao IS 'Nome completo do módulo. (Informação obtida da GE_MODULO)';


--
-- Name: modulo_seq_modulo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE modulo_seq_modulo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE modulo_seq_modulo_seq OWNER TO postgres;

--
-- Name: modulo_seq_modulo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE modulo_seq_modulo_seq OWNED BY modulo.seq_modulo;


--
-- Name: pamonha; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE pamonha (
    seq integer,
    nome character varying(100)
);


ALTER TABLE pamonha OWNER TO postgres;

--
-- Name: ptf; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ptf (
    seq_ptf integer NOT NULL,
    versao integer NOT NULL,
    sprint integer NOT NULL,
    release integer NOT NULL
);


ALTER TABLE ptf OWNER TO postgres;

--
-- Name: TABLE ptf; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE ptf IS 'Tabela criada para armazenar as informações referente as PTFs (Atualizações) que a empresa libera. ';


--
-- Name: COLUMN ptf.versao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN ptf.versao IS 'Coluna numérica (inteira) que identifica a versão da aplicação. (geralmente a empresa trabalha com versões anuais, em uma sistema de ômega e delta)';


--
-- Name: COLUMN ptf.sprint; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN ptf.sprint IS 'Coluna numérica (Inteira) que identifica o sprint atual da versão. (geralmente a empresa atrabalha com sprint anual)';


--
-- Name: COLUMN ptf.release; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN ptf.release IS 'Coluna numérica (Inteira) que identifica as atualizações constantes.';


--
-- Name: ptf_modulo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ptf_modulo (
    seq_ptf_modulo integer NOT NULL,
    seq_ptf integer NOT NULL,
    seq_modulo integer NOT NULL
);


ALTER TABLE ptf_modulo OWNER TO postgres;

--
-- Name: ptf_modulo_seq_ptf_modulo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE ptf_modulo_seq_ptf_modulo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ptf_modulo_seq_ptf_modulo_seq OWNER TO postgres;

--
-- Name: ptf_modulo_seq_ptf_modulo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE ptf_modulo_seq_ptf_modulo_seq OWNED BY ptf_modulo.seq_ptf_modulo;


--
-- Name: ptf_seq_ptf_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE ptf_seq_ptf_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ptf_seq_ptf_seq OWNER TO postgres;

--
-- Name: ptf_seq_ptf_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE ptf_seq_ptf_seq OWNED BY ptf.seq_ptf;


--
-- Name: rating; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE rating (
    seq_rating integer NOT NULL,
    seq_ptf integer NOT NULL,
    seq_modulo integer NOT NULL,
    seq_aplicacao integer NOT NULL,
    seq_sugestao_erro integer NOT NULL,
    stacktrace text,
    solucionado character varying(1) DEFAULT 'N'::character varying,
    rating numeric(5,2),
    total_sim integer,
    total_nao integer
);


ALTER TABLE rating OWNER TO postgres;

--
-- Name: rating_seq_rating_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE rating_seq_rating_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE rating_seq_rating_seq OWNER TO postgres;

--
-- Name: rating_seq_rating_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE rating_seq_rating_seq OWNED BY rating.seq_rating;


--
-- Name: sugestao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE sugestao (
    seq_sugestao integer NOT NULL,
    descricao character varying(4000) NOT NULL,
    detalhes text NOT NULL
);


ALTER TABLE sugestao OWNER TO postgres;

--
-- Name: TABLE sugestao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE sugestao IS 'Tabela criada para armazenar as sugestões de solução para os erros conhecidos.';


--
-- Name: COLUMN sugestao.descricao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN sugestao.descricao IS 'Coluna texto com a descrição detalhada da sugestão para que seja possível executar os passos e solucionar o erro.';


--
-- Name: COLUMN sugestao.detalhes; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN sugestao.detalhes IS 'Coluna para armazenar imagens ou outros tipos de documentos que disponibilizados pelos empresa, ajudem o cliente a aplicar a sugestão.';


--
-- Name: sugestao_erro; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE sugestao_erro (
    seq_sugestao_erro integer NOT NULL,
    seq_erro integer NOT NULL,
    seq_sugestao integer NOT NULL,
    ocorrencia integer DEFAULT 0,
    relevancia real DEFAULT 0,
    contorno integer DEFAULT 0
);


ALTER TABLE sugestao_erro OWNER TO postgres;

--
-- Name: TABLE sugestao_erro; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE sugestao_erro IS 'Tabela criada para armazenar a relação entre sugestões e erros conhecidos.';


--
-- Name: COLUMN sugestao_erro.ocorrencia; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN sugestao_erro.ocorrencia IS 'Coluna numérica (Inteira) que funciona como contador para todas as vezes que o cliente acessar essa sugestão e informar que o problema foi solucionado.';


--
-- Name: COLUMN sugestao_erro.relevancia; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN sugestao_erro.relevancia IS 'Coluna numérica (decimal) que armazena o valor normalizado da sugestão, em relação as demais sugestões do mesmo erro.';


--
-- Name: COLUMN sugestao_erro.contorno; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN sugestao_erro.contorno IS 'Coluna numérica (Inteira) para armazenar o número do RC, caso a sugestão necessite de aplicação de alterações pela empresa.';


--
-- Name: sugestao_erro_seq_sugestao_erro_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE sugestao_erro_seq_sugestao_erro_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sugestao_erro_seq_sugestao_erro_seq OWNER TO postgres;

--
-- Name: sugestao_erro_seq_sugestao_erro_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE sugestao_erro_seq_sugestao_erro_seq OWNED BY sugestao_erro.seq_sugestao_erro;


--
-- Name: sugestao_seq_sugestao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE sugestao_seq_sugestao_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sugestao_seq_sugestao_seq OWNER TO postgres;

--
-- Name: sugestao_seq_sugestao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE sugestao_seq_sugestao_seq OWNED BY sugestao.seq_sugestao;


--
-- Name: teste; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE teste (
    id integer NOT NULL,
    name character varying(20)
);


ALTER TABLE teste OWNER TO postgres;

--
-- Name: teste_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE teste_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE teste_id_seq OWNER TO postgres;

--
-- Name: teste_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE teste_id_seq OWNED BY teste.id;


--
-- Name: anexo seq_anexo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY anexo ALTER COLUMN seq_anexo SET DEFAULT nextval('anexo_seq_anexo_seq'::regclass);


--
-- Name: aplicacao seq_aplicacao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY aplicacao ALTER COLUMN seq_aplicacao SET DEFAULT nextval('aplicacao_seq_aplicacao_seq'::regclass);


--
-- Name: erro seq_erro; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY erro ALTER COLUMN seq_erro SET DEFAULT nextval('erro_seq_erro_seq'::regclass);


--
-- Name: modulo seq_modulo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY modulo ALTER COLUMN seq_modulo SET DEFAULT nextval('modulo_seq_modulo_seq'::regclass);


--
-- Name: ptf seq_ptf; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ptf ALTER COLUMN seq_ptf SET DEFAULT nextval('ptf_seq_ptf_seq'::regclass);


--
-- Name: ptf_modulo seq_ptf_modulo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ptf_modulo ALTER COLUMN seq_ptf_modulo SET DEFAULT nextval('ptf_modulo_seq_ptf_modulo_seq'::regclass);


--
-- Name: rating seq_rating; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY rating ALTER COLUMN seq_rating SET DEFAULT nextval('rating_seq_rating_seq'::regclass);


--
-- Name: sugestao seq_sugestao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY sugestao ALTER COLUMN seq_sugestao SET DEFAULT nextval('sugestao_seq_sugestao_seq'::regclass);


--
-- Name: sugestao_erro seq_sugestao_erro; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY sugestao_erro ALTER COLUMN seq_sugestao_erro SET DEFAULT nextval('sugestao_erro_seq_sugestao_erro_seq'::regclass);


--
-- Name: teste id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY teste ALTER COLUMN id SET DEFAULT nextval('teste_id_seq'::regclass);


--
-- Data for Name: anexo; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY anexo (seq_anexo, descricao, anexo, seq_erro) FROM stdin;
\.


--
-- Name: anexo_seq_anexo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('anexo_seq_anexo_seq', 1, false);


--
-- Data for Name: aplicacao; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY aplicacao (seq_aplicacao, aplicacao, descricao, seq_modulo) FROM stdin;
1	MAX4208	Análise ABC de Rupturas	1
2	MAD00152	Campanha	1
3	MAD00002	Relatório de Resultado de Campanha	1
4	DOM0010	Manutenção de Movimentos	2
5	DOM0034	Importação de Bens	2
6	DOM0014	Consulta Bens	2
7	MAX0096A	Recebimento de Notas Fiscais	3
8	MAX0070	Local	3
9	MFL000800	Digitação Manual Redução Z	3
10	ORPARAMETRO	Parâmetros de Orçamento	4
11	ORBONUSTRANS	Lançamento de Bônus / Transferência de V	4
12	ORC00006	Alçada de Requisição por Usuário	4
13	RFMANUTCFOP	CFOP	5
14	RFMANUTNF	Notas Fiscais	5
15	RFMANPRODUTO	Produtos	5
16	ABA_00027	Balancete de Apuração	6
17	ABA_00040	Modelo de Exportação	6
18	ABA_00054	Versões, Blocos e Registros - ECF	6
19	CTRPLANCONT	Relatório de Plano de Contas	7
20	CTLANCAMENTO	Lançamentos	7
21	CTPLACONTA	Plano de Contas	7
22	FIS00046	Apuração PIS/COFINS - Nova	5
23	FIS00002	Geração EFD - Contribuições	5
\.


--
-- Name: aplicacao_seq_aplicacao_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('aplicacao_seq_aplicacao_seq', 23, true);


--
-- Data for Name: erro; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY erro (seq_erro, titulo, descricao, tags, ocorrencia, relevancia, detalhes, seq_aplicacao) FROM stdin;
27	teste	teste 01	teste	0	0	 	22
4	Valor do Apuração de Pis/Cofins demonstrado no Registro M105/M505	Devido o Modelo do Documento ser um modelo em desacordo, o Documento Fiscal não é gerado no arquivo do SPED Contribuições	Modelo Documento, M105, M505, Energia Elétrica	5	0.833333313	 	22
5	Erro de Estrutura Árvore	Erro de Estrutura ao validar do arquivo do SPED Contribuições	estrutura	5	0.833333313	 	22
3	Divergências nos Registros M105/M505	A soma dos Totalizadores não conferem com o apresentado nos Registros M105/M505 	M105, M505, Divergências, Somatória	6	1	 	22
2	Erro na importação de documentos fiscais	Durante a importação de notas fiscais, seja em processo automático ou manual, as notas fiscais não estão sendo importadas para o fiscal. Quando feito por meio manual é possível ver o erro que aparece em tela dizendo que ocorreu um erros interno no sistema e a aplicação fecha.	importação,notas,fiscais,fiscal	25	1	Teste Somente	7
6	Como atualizar o layout do SPED Contribuições?	O layout antigo expirou e preciso cadastrar um novo layout que entra em vigor. Como faço?	layout, novo layout	0	0	 	23
25	Como alterar o layout do SPED	O layout foi alterado para uma versão nova, e preciso de um novo layout.	layout, SPED	0	0	 	23
26	Erro SQL  para o registro 0150	Ocorreram erros ao gerar o arquivo para EFD. Erro ao gerar: Bloco 0. Erro ao inserir registro 0150	SQL, 0150	0	0	 	23
\.


--
-- Name: erro_seq_erro_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('erro_seq_erro_seq', 27, true);


--
-- Data for Name: modulo; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY modulo (seq_modulo, modulo, sigla, descricao) FROM stdin;
1	GERENCIAL	GER	Acrux Gerencial
2	DOMINI	DOM	Acrux Domini
3	MAXST_LOJA	LOJA	Acrux Loja
4	ORCAMENTO	ORC	Acrux Orçamento
5	FISCAL	F	Acrux Fisci
6	ABACI_WEB	ABA	Abaci Web
7	CONTABIL	OPCT	Acrux Abaci
\.


--
-- Name: modulo_seq_modulo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('modulo_seq_modulo_seq', 7, true);


--
-- Data for Name: pamonha; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY pamonha (seq, nome) FROM stdin;
\N	2017-11-29 21:41:48.902856+00 iNSERÇÃO;  Erro: 3 Sugestão: 4
\N	2017-11-29 22:00:54.405252+00 iNSERÇÃO;  Erro: 3 Sugestão: 4
\N	2017-11-29 22:02:15.456016+00 iNSERÇÃO;  Erro: 3 Sugestão: 4
\N	2017-11-29 22:03:39.41383+00 iNSERÇÃO;  Erro: 3 Sugestão: 4
\N	2017-11-29 22:04:11.148779+00 iNSERÇÃO;  Erro: 3 Sugestão: 4
\N	2017-12-03 21:30:04.499557+00 iNSERÇÃO;  Erro: 2 Sugestão: 2
\N	2017-12-03 21:33:50.090223+00 iNSERÇÃO;  Erro: 5 Sugestão: 8
\N	2017-12-03 21:35:04.724013+00 iNSERÇÃO;  Erro: 2 Sugestão: 2
\N	2017-12-03 21:36:39.152312+00 iNSERÇÃO;  Erro: 4 Sugestão: 6
\N	2017-12-03 21:38:45.480113+00 iNSERÇÃO;  Erro: 2 Sugestão: 2
\N	2017-12-03 21:47:00.66331+00 iNSERÇÃO;  Erro: 2 Sugestão: 2
\N	2017-12-03 21:48:12.644676+00 iNSERÇÃO;  Erro: 2 Sugestão: 2
\N	2017-12-08 00:21:27.719665+00 iNSERÇÃO;  Erro: 4 Sugestão: 6
\N	2017-12-08 00:22:34.930325+00 iNSERÇÃO;  Erro: 4 Sugestão: 6
\N	2017-12-08 12:27:19.342079+00 iNSERÇÃO;  Erro: 5 Sugestão: 8
\N	2017-12-08 12:58:52.637677+00 iNSERÇÃO;  Erro: 3 Sugestão: 2
\N	2017-12-08 13:19:45.234479+00 iNSERÇÃO;  Erro: 5 Sugestão: 8
\N	2017-12-08 13:31:02.079599+00 iNSERÇÃO;  Erro: 3 Sugestão: 1
\N	2017-12-08 14:00:08.067561+00 iNSERÇÃO;  Erro: 3 Sugestão: 1
\N	2017-12-10 13:38:48.613353+00 iNSERÇÃO;  Erro: 5 Sugestão: 8
\N	2017-12-15 13:07:49.574479+00 iNSERÇÃO;  Erro: 4 Sugestão: 6
\N	2017-12-15 16:05:10.225516+00 iNSERÇÃO;  Erro: 5 Sugestão: 8
\N	2017-12-16 19:39:05.855969+00 iNSERÇÃO;  Erro: 3 Sugestão: 1
\N	2017-12-20 15:11:48.427903+00 iNSERÇÃO;  Erro: 3 Sugestão: 2
\.


--
-- Data for Name: ptf; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY ptf (seq_ptf, versao, sprint, release) FROM stdin;
1	18	1	14
2	17	1	203
\.


--
-- Data for Name: ptf_modulo; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY ptf_modulo (seq_ptf_modulo, seq_ptf, seq_modulo) FROM stdin;
1	1	1
2	1	2
3	1	3
4	1	4
5	1	5
6	1	6
7	1	7
8	2	1
9	2	2
10	2	3
11	2	4
12	2	5
13	2	6
14	2	7
\.


--
-- Name: ptf_modulo_seq_ptf_modulo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('ptf_modulo_seq_ptf_modulo_seq', 14, true);


--
-- Name: ptf_seq_ptf_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('ptf_seq_ptf_seq', 2, true);


--
-- Data for Name: rating; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY rating (seq_rating, seq_ptf, seq_modulo, seq_aplicacao, seq_sugestao_erro, stacktrace, solucionado, rating, total_sim, total_nao) FROM stdin;
2	1	3	7	1	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX LOJA - MAXST_LOJA, MAX0096A, conheço o incidente ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, ERRO NA IMPORTAÇÃO DE DOCUMENTOS FISCAIS é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Foi verificado se o CGO está ajustado para permitir a importação? \\n >>[Nick]:O CGO possue um parâmetro que determina de quais as origens permitidas para importação de documentos. Onde verifica: Módulo Parâmetros -> Configuração -> CGO -> Aba Fiscal -> Parâmetro Doc. Origens, ajuste para permitir documentos vindos do SM e pressione o botão atualizar. \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Sem problemas! Tente este: \\n >>[Nick]:Já verificou o parâmetro dinâmico  Import_Docs_Processados"? \\n >>[Nick]:Esse parâmetro determina se o módulo irá importar os documentos fiscais vindos do módulo de entrada, para que esses documentos sejam processados o parâmetro deve ter o valor  S". Onde verifica: Módulo Fiscal -> Configuração -> Empresa -> Parâmetro Dinâmico -> Digite o nome do parâmetro e pressione F8. \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	3.00	2	1
3	1	5	22	6	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, DIVERGÊNCIAS NOS REGISTROS M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Certo, ERRO DE ESTRUTURA ARVORE é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Emitir a Conferência do Apuração de Pis/Cofins 22 \\n >>[Nick]:Primeiro, imprima o Apuração de Pis/Cofins e confiram as alíquotas de acordo com o Regime de sua Empresa.  \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Infelizmente ainda não consegui resolver seu problema e não tenho mais ideias. Mas tudo bem. Vou anotar seu chamado para um atendente. Na próxima estarei mais esperto	N	1.00	2	1
4	1	5	22	15	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, DIVERGÊNCIAS NOS REGISTROS M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Já verificou o parâmetro dinâmico  Import_Docs_Processados"? \\n >>[Nick]:Esse parâmetro determina se o módulo irá importar os documentos fiscais vindos do módulo de entrada, para que esses documentos sejam processados o parâmetro deve ter o valor  S". Onde verifica: Módulo Fiscal -> Configuração -> Empresa -> Parâmetro Dinâmico -> Digite o nome do parâmetro e pressione F8. \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	5.00	2	0
5	1	3	7	3	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX LOJA - MAXST_LOJA, MAX0096A, conheço o incidente ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, ERRO NA IMPORTAÇÃO DE DOCUMENTOS FISCAIS é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Foi verificado se o CGO está ajustado para permitir a importação? \\n >>[Nick]:O CGO possu um parâmetro que determina de quais as origens permitidas para importação de documentos. Onde verifica: Módulo Parâmetros -> Configuração -> CGO -> Aba Fiscal -> Parâmetro Doc. Origens, ajuste para permitir documentos vindos do SM e pressione o botão atualizar. \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Sem problemas! Tente este: \\n >>[Nick]:Já verificou o parâmetro dinâmico  Import_Docs_Processados"? \\n >>[Nick]:Esse parâmetro determina se o módulo irá importar os documentos fiscais vindos do módulo de entrada, para que esses documentos sejam processados o parâmetro deve ter o valor  S". Onde verifica: Módulo Fiscal -> Configuração -> Empresa -> Parâmetro Dinâmico -> Digite o nome do parâmetro e pressione F8. \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Hum Ok! Experimente isto. \\n >>[Nick]:Necessário aplicação de ajuste técnico na aplicação. \\n >>[Nick]:Após ser direcionado á consultora, será realizado o procedimento necessário para ajustar a aplicação com ajustes da empresa na base de dados e aplicação. \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	2.00	2	2
7	1	5	22	15	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, DIVERGÊNCIAS NOS REGISTROS M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Já verificou o parâmetro dinâmico  Import_Docs_Processados"? \\n >>[Nick]:Esse parâmetro determina se o módulo irá importar os documentos fiscais vindos do módulo de entrada, para que esses documentos sejam processados o parâmetro deve ter o valor  S". Onde verifica: Módulo Fiscal -> Configuração -> Empresa -> Parâmetro Dinâmico -> Digite o nome do parâmetro e pressione F8. \\n   **[User]:NÃO \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:NÃO \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, ERRO DE ESTRUTURA ARVORE é  o que está ocorrendo? Responda. \\n   **[User]:NÃO \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:NÃO \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, DIVERGÊNCIAS NOS REGISTROS M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:NÃO \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:NÃO \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, ERRO DE ESTRUTURA ARVORE é  o que está ocorrendo? Responda. \\n   **[User]:NÃO \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:NÃO \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, ERRO DE ESTRUTURA ARVORE é  o que está ocorrendo? Responda. \\n   **[User]:NÃO \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:NÃO \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, DIVERGÊNCIAS NOS REGISTROS M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:NÃO \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:NÃO \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, ERRO DE ESTRUTURA ARVORE é  o que está ocorrendo? Responda. \\n   **[User]:NÃO \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, DIVERGÊNCIAS NOS REGISTROS M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:NÃO \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:NÃO \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, ERRO DE ESTRUTURA ARVORE é  o que está ocorrendo? Responda. \\n   **[User]:NÃO \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:NÃO \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, DIVERGÊNCIAS NOS REGISTROS M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:NÃO \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:NÃO \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, ERRO DE ESTRUTURA ARVORE é  o que está ocorrendo? Responda. \\n   **[User]:NÃO \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, DIVERGÊNCIAS NOS REGISTROS M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	2.00	2	0
9	1	3	7	1	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX LOJA - MAXST_LOJA, MAX0096A, conheço o incidente ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, ERRO NA IMPORTAÇÃO DE DOCUMENTOS FISCAIS é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Foi verificado se o CGO está ajustado para permitir a importação? \\n >>[Nick]:O CGO possu um parâmetro que determina de quais as origens permitidas para importação de documentos. Onde verifica: Módulo Parâmetros -> Configuração -> CGO -> Aba Fiscal -> Parâmetro Doc. Origens, ajuste para permitir documentos vindos do SM e pressione o botão atualizar. \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Sem problemas! Tente este: \\n >>[Nick]:Já verificou o parâmetro dinâmico  Import_Docs_Processados"? \\n >>[Nick]:Esse parâmetro determina se o módulo irá importar os documentos fiscais vindos do módulo de entrada, para que esses documentos sejam processados o parâmetro deve ter o valor  S". Onde verifica: Módulo Fiscal -> Configuração -> Empresa -> Parâmetro Dinâmico -> Digite o nome do parâmetro e pressione F8. \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	4.00	2	1
11	2	5	23	34	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00002, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, COMO ATUALIZAR O LAYOUT DO SPED CONTRIBUIÇÕES? é  o que está ocorrendo? Responda. \\n >>[Nick]:Certo, COMO ATUALIZAR O LAYOUT DO SPED CONTRIBUIÇÕES? é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Emitir o Relatório Conferência do Apuração de Pis/Cofins Outro outro outro \\n >>[Nick]:Caminho do Relatório: Fiscal/ Processos/ Apuração de Pis/Cofins/ Conferência do Apuração de Pis/Cofins. Em  CST", selecione "Entradas", e selecione os CSTs que forem geradores de Crédito de Pis/Cofins (Exemplo: 50, 53). Em "Tipo de Relatório", selecionar a opção "Resumo por Nat. Base Cred. e CST" e localiza o CST com a divergência. Após idenfiticado o CST com divergência, emita novamente o Relatório, agora, utilizando os filtros: em "CST", selecione "Entradas", e selecione os CSTs que foi identificado no Relatório anterior, em "Tipo de Relatório", selecionar a opção "Sintético por Documento". Em seguida, localizar o movimento que estiver com Natureza da Base de Cálculo do Crédito nula. Através do Relatório identifique o Documento, corrija-o e faça ao procedimento de Recomposição do Apuração (caminho: Através da Empresa Matriz, acessar: Fiscal/Processos/Apuração de Pis/Cofins/Apuração de Pis/Cofins/Demonstrar e Imprimir Dados Consolidados/Recompor Apuração \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Sem problemas! Tente este: \\n >>[Nick]:Troca de layout \\n >>[Nick]:Após disponibilização da SEFAZ, se fez necessário a alteração do layout para a versão 12.1. Acesse o Fiscal, Manutenção, ... \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	2.00	2	1
12	2	5	22	14	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, DIVERGÊNCIAS NOS REGISTROS M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Já verificou o parâmetro dinâmico  Import_Docs_Processados"? \\n >>[Nick]:Esse parâmetro determina se o módulo irá importar os documentos fiscais vindos do módulo de entrada, para que esses documentos sejam processados o parâmetro deve ter o valor  S". Onde verifica: Módulo Fiscal -> Configuração -> Empresa -> Parâmetro Dinâmico -> Digite o nome do parâmetro e pressione F8. \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Sem problemas! Tente este: \\n >>[Nick]:Foi verificado se o CGO está ajustado para permitir a importação? \\n >>[Nick]:O CGO possui um parâmetro que determina de quais as origens permitidas para importação de documentos. Onde verifica: Módulo Parâmetros -> Configuração -> CGO -> Aba Fiscal -> Parâmetro Doc. Origens, ajuste para permitir documentos vindos do SM e pressione o botão atualizar. \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	5.00	2	1
13	1	5	22	14	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, DIVERGÊNCIAS NOS REGISTROS M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Já verificou o parâmetro dinâmico  Import_Docs_Processados"? \\n >>[Nick]:Esse parâmetro determina se o módulo irá importar os documentos fiscais vindos do módulo de entrada, para que esses documentos sejam processados o parâmetro deve ter o valor  S". Onde verifica: Módulo Fiscal -> Configuração -> Empresa -> Parâmetro Dinâmico -> Digite o nome do parâmetro e pressione F8. \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Sem problemas! Tente este: \\n >>[Nick]:Foi verificado se o CGO está ajustado para permitir a importação? \\n >>[Nick]:O CGO possui um parâmetro que determina de quais as origens permitidas para importação de documentos. Onde verifica: Módulo Parâmetros -> Configuração -> CGO -> Aba Fiscal -> Parâmetro Doc. Origens, ajuste para permitir documentos vindos do SM e pressione o botão atualizar. \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Infelizmente ainda não consegui resolver seu problema e não tenho mais ideias. Mas tudo bem. Vou anotar seu chamado para um atendente. Na próxima estarei mais esperto	N	3.00	1	2
14	1	5	22	6	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, ERRO DE ESTRUTURA ARVORE é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Emitir a Conferência do Apuração de Pis/Cofins \\n >>[Nick]:Primeiro, imprima o Apuração de Pis/Cofins e confiram as alíquotas de acordo com o Regime de sua Empresa.  \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	5.00	2	0
15	1	5	22	15	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, DIVERGÊNCIAS NOS REGISTROS M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Já verificou o parâmetro dinâmico  Import_Docs_Processados"? \\n >>[Nick]:Esse parâmetro determina se o módulo irá importar os documentos fiscais vindos do módulo de entrada, para que esses documentos sejam processados o parâmetro deve ter o valor  S". Onde verifica: Módulo Fiscal -> Configuração -> Empresa -> Parâmetro Dinâmico -> Digite o nome do parâmetro e pressione F8. \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	5.00	2	0
22	2	5	22	6	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, DIVERGÊNCIAS NOS REGISTROS M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:NÃO \\n >>[Nick]:Sem Problemas! Escolha outra opção. \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, ERRO DE ESTRUTURA ÁRVORE é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Emitir a Conferência do Apuração de Pis/Cofins \\n >>[Nick]:Imprima o Apuração de Pis/Cofins (Módulo: Fiscal, Aba: Processos, Apuração de Pis/Cofins) e confiram as alíquotas de acordo com o Regime de sua Empresa.  \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Infelizmente ainda não consegui resolver seu problema e não tenho mais ideias. Mas tudo bem. Vou anotar seu chamado para um atendente. Na próxima estarei mais esperto	N	4.00	1	2
16	1	5	22	14	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, DIVERGÊNCIAS NOS REGISTROS M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Já verificou o parâmetro dinâmico  Import_Docs_Processados"? \\n >>[Nick]:Esse parâmetro determina se o módulo irá importar os documentos fiscais vindos do módulo de entrada, para que esses documentos sejam processados o parâmetro deve ter o valor  S". Onde verifica: Módulo Fiscal -> Configuração -> Empresa -> Parâmetro Dinâmico -> Digite o nome do parâmetro e pressione F8. \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Sem problemas! Tente este: \\n >>[Nick]:Foi verificado se o CGO está ajustado para permitir a importação? \\n >>[Nick]:O CGO possui um parâmetro que determina de quais as origens permitidas para importação de documentos. Onde verifica: Módulo Parâmetros -> Configuração -> CGO -> Aba Fiscal -> Parâmetro Doc. Origens, ajuste para permitir documentos vindos do SM e pressione o botão atualizar. \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	4.00	2	1
17	1	5	22	15	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, DIVERGÊNCIAS NOS REGISTROS M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Já verificou o parâmetro dinâmico  Import_Docs_Processados"? \\n >>[Nick]:Esse parâmetro determina se o módulo irá importar os documentos fiscais vindos do módulo de entrada, para que esses documentos sejam processados o parâmetro deve ter o valor  S". Onde verifica: Módulo Fiscal -> Configuração -> Empresa -> Parâmetro Dinâmico -> Digite o nome do parâmetro e pressione F8. \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	5.00	2	0
18	1	5	22	14	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, DIVERGÊNCIAS NOS REGISTROS M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Já verificou o parâmetro dinâmico  Import_Docs_Processados"? \\n >>[Nick]:Esse parâmetro determina se o módulo irá importar os documentos fiscais vindos do módulo de entrada, para que esses documentos sejam processados o parâmetro deve ter o valor  S". Onde verifica: Módulo Fiscal -> Configuração -> Empresa -> Parâmetro Dinâmico -> Digite o nome do parâmetro e pressione F8. \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Sem problemas! Tente este: \\n >>[Nick]:Foi verificado se o CGO está ajustado para permitir a importação? \\n >>[Nick]:O CGO possui um parâmetro que determina de quais as origens permitidas para importação de documentos. Onde verifica: Módulo Parâmetros -> Configuração -> CGO -> Aba Fiscal -> Parâmetro Doc. Origens, ajuste para permitir documentos vindos do SM e pressione o botão atualizar. \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Infelizmente ainda não consegui resolver seu problema e não tenho mais ideias. Mas tudo bem. Vou anotar seu chamado para um atendente. Na próxima estarei mais esperto	N	3.00	1	2
19	1	5	22	38	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Emitir o Relatório Conferência do Apuração de Pis/Cofins  \\n >>[Nick]:Caminho do Relatório: Fiscal/ Processos/ Apuração de Pis/Cofins/ Conferência do Apuração de Pis/Cofins. Usar os Filtros: CST e Natureza da Base do Cálculo do Crédito.Em  Tipo de Relatório", selecionar a opção "Sintético por Documento". Em "CST", selecione "Entradas", e selecione os CSTs que apresentarem no erro do SPED, Registros M105 e M505. O mesmo procedimento, deve ser realizado para a Natureza da Base de Cálculo do Crédito. Exemplo: Documentos Integrados com o CFOP 1253, que correspondem à Energia Elétrica integrados com Modelo de Documento 55 sendo que o Registro C500 aceita Modelos de Energia Elétrica ( 06, 28, 29) \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Sem problemas! Tente este: \\n >>[Nick]:Emitir o Apuração de Pis/Cofins \\n >>[Nick]:Emitir o Apuração de Pis/Cofins e conciliar os CST e CFOPS geradores de créditos, com o Relatório de Conferência de Pis/Cofins \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	5.00	2	1
20	1	5	22	14	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, DIVERGÊNCIAS NOS REGISTROS M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Já verificou o parâmetro dinâmico  Import_Docs_Processados"? \\n >>[Nick]:Esse parâmetro determina se o módulo irá importar os documentos fiscais vindos do módulo de entrada, para que esses documentos sejam processados o parâmetro deve ter o valor  S". Onde verifica: Módulo Fiscal -> Configuração -> Empresa -> Parâmetro Dinâmico -> Digite o nome do parâmetro e pressione F8. \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Sem problemas! Tente este: \\n >>[Nick]:Foi verificado se o CGO está ajustado para permitir a importação? \\n >>[Nick]:O CGO possui um parâmetro que determina de quais as origens permitidas para importação de documentos. Onde verifica: Módulo Parâmetros -> Configuração -> CGO -> Aba Fiscal -> Parâmetro Doc. Origens, ajuste para permitir documentos vindos do SM e pressione o botão atualizar. \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Infelizmente ainda não consegui resolver seu problema e não tenho mais ideias. Mas tudo bem. Vou anotar seu chamado para um atendente. Na próxima estarei mais esperto	N	5.00	1	2
21	1	5	22	5	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Emitir o Relatório Conferência do Apuração de Pis/Cofins  \\n >>[Nick]:Caminho do Relatório: Fiscal/ Processos/ Apuração de Pis/Cofins/ Conferência do Apuração de Pis/Cofins. Usar os Filtros: CST e Natureza da Base do Cálculo do Crédito.Em  Tipo de Relatório", selecionar a opção "Sintético por Documento". Em "CST", selecione "Entradas", e selecione os CSTs que apresentarem no erro do SPED, Registros M105 e M505. O mesmo procedimento, deve ser realizado para a Natureza da Base de Cálculo do Crédito. Exemplo: Documentos Integrados com o CFOP 1253, que correspondem à Energia Elétrica integrados com Modelo de Documento 55 sendo que o Registro C500 aceita Modelos de Energia Elétrica ( 06, 28, 29) \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	5.00	2	0
23	2	5	23	37	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00002, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, ERRO SQL  PARA O REGISTRO 0150 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Erro SQL  para o registro 0150 \\n >>[Nick]:Situação solucionada pelo requisito 173670 que está liberado nas versões 17.01.160 PTF 17.01-215 (Ômega) e 18.01.011 PTF 18.01-011 (Delta).  Por gentileza, atualize a versão para correção do seu problema. \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	5.00	2	0
24	2	5	22	39	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Emitir o Relatório Conferência do Apuração de Pis/Cofins  \\n >>[Nick]:Caminho do Relatório: Fiscal/ Processos/ Apuração de Pis/Cofins/ Conferência do Apuração de Pis/Cofins. Usar os Filtros: CST e Natureza da Base do Cálculo do Crédito.Em  Tipo de Relatório", selecionar a opção "Sintético por Documento". Em "CST", selecione "Entradas", e selecione os CSTs que apresentarem no erro do SPED, Registros M105 e M505. O mesmo procedimento, deve ser realizado para a Natureza da Base de Cálculo do Crédito. Exemplo: Documentos Integrados com o CFOP 1253, que correspondem à Energia Elétrica integrados com Modelo de Documento 55 sendo que o Registro C500 aceita Modelos de Energia Elétrica ( 06, 28, 29) \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Sem problemas! Tente este: \\n >>[Nick]:Emitir o Apuração de Pis/Cofins \\n >>[Nick]:Emitir o Apuração de Pis/Cofins e conciliar os CST e CFOPS geradores de créditos, com o Relatório de Conferência de Pis/Cofins \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Hum Ok! Experimente isto. \\n >>[Nick]:Emitir o Relatório Operações e Prestações por UF \\n >>[Nick]:Emitir o Relatório de Operações e Prestações por UF. Módulo: Fiscal, Aba: Relatórios, Relatório: Operações e Prestações por UF. Informe o período e gere o relatório.\nConfira os valores, categorizando por CFOP, com o Apuração de Pis/Cofins \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Infelizmente ainda não consegui resolver seu problema e não tenho mais ideias. Mas tudo bem. Vou anotar seu chamado para um atendente. Na próxima estarei mais esperto	N	1.00	1	3
25	1	5	22	15	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, DIVERGÊNCIAS NOS REGISTROS M105/M505 é  o que está ocorrendo? Responda. \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, ERRO DE ESTRUTURA ÁRVORE é  o que está ocorrendo? Responda. \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:NÃO \\n >>[Nick]:Sem Problemas! Escolha outra opção. \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, DIVERGÊNCIAS NOS REGISTROS M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Já verificou o parâmetro dinâmico  Import_Docs_Processados"? \\n >>[Nick]:Esse parâmetro determina se o módulo irá importar os documentos fiscais vindos do módulo de entrada, para que esses documentos sejam processados o parâmetro deve ter o valor  S". Onde verifica: Módulo Fiscal -> Configuração -> Empresa -> Parâmetro Dinâmico -> Digite o nome do parâmetro e pressione F8. \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	5.00	2	1
26	1	5	22	39	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, DIVERGÊNCIAS NOS REGISTROS M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:NÃO \\n >>[Nick]:Sem Problemas! Escolha outra opção. \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Emitir o Relatório Conferência do Apuração de Pis/Cofins  \\n >>[Nick]:Caminho do Relatório: Fiscal/ Processos/ Apuração de Pis/Cofins/ Conferência do Apuração de Pis/Cofins. Usar os Filtros: CST e Natureza da Base do Cálculo do Crédito.Em  Tipo de Relatório", selecionar a opção "Sintético por Documento". Em "CST", selecione "Entradas", e selecione os CSTs que apresentarem no erro do SPED, Registros M105 e M505. O mesmo procedimento, deve ser realizado para a Natureza da Base de Cálculo do Crédito. Exemplo: Documentos Integrados com o CFOP 1253, que correspondem à Energia Elétrica integrados com Modelo de Documento 55 sendo que o Registro C500 aceita Modelos de Energia Elétrica ( 06, 28, 29) \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Sem problemas! Tente este: \\n >>[Nick]:Emitir o Apuração de Pis/Cofins \\n >>[Nick]:Emitir o Apuração de Pis/Cofins e conciliar os CST e CFOPS geradores de créditos, com o Relatório de Conferência de Pis/Cofins \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Hum Ok! Experimente isto. \\n >>[Nick]:Emitir o Relatório Operações e Prestações por UF \\n >>[Nick]:Emitir o Relatório de Operações e Prestações por UF. Módulo: Fiscal, Aba: Relatórios, Relatório: Operações e Prestações por UF. Informe o período e gere o relatório.\nConfira os valores, categorizando por CFOP, com o Apuração de Pis/Cofins \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	4.00	2	3
27	1	5	22	38	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Emitir o Relatório Conferência do Apuração de Pis/Cofins  \\n >>[Nick]:Caminho do Relatório: Fiscal/ Processos/ Apuração de Pis/Cofins/ Conferência do Apuração de Pis/Cofins. Usar os Filtros: CST e Natureza da Base do Cálculo do Crédito.Em  Tipo de Relatório", selecionar a opção "Sintético por Documento". Em "CST", selecione "Entradas", e selecione os CSTs que apresentarem no erro do SPED, Registros M105 e M505. O mesmo procedimento, deve ser realizado para a Natureza da Base de Cálculo do Crédito. Exemplo: Documentos Integrados com o CFOP 1253, que correspondem à Energia Elétrica integrados com Modelo de Documento 55 sendo que o Registro C500 aceita Modelos de Energia Elétrica ( 06, 28, 29) \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Sem problemas! Tente este: \\n >>[Nick]:Emitir o Apuração de Pis/Cofins \\n >>[Nick]:Emitir o Apuração de Pis/Cofins e conciliar os CST e CFOPS geradores de créditos, com o Relatório de Conferência de Pis/Cofins \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	3.00	2	1
40	1	5	22	6	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, ERRO DE ESTRUTURA ÁRVORE é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Emitir a Conferência do Apuração de Pis/Cofins \\n >>[Nick]:Imprima o Apuração de Pis/Cofins (Módulo: Fiscal, Aba: Processos, Apuração de Pis/Cofins) e confiram as alíquotas de acordo com o Regime de sua Empresa.  \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	5.00	2	0
28	1	5	22	5	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Emitir o Relatório Conferência do Apuração de Pis/Cofins  \\n >>[Nick]:Caminho do Relatório: Fiscal/ Processos/ Apuração de Pis/Cofins/ Conferência do Apuração de Pis/Cofins. Usar os Filtros: CST e Natureza da Base do Cálculo do Crédito.Em  Tipo de Relatório", selecionar a opção "Sintético por Documento". Em "CST", selecione "Entradas", e selecione os CSTs que apresentarem no erro do SPED, Registros M105 e M505. O mesmo procedimento, deve ser realizado para a Natureza da Base de Cálculo do Crédito. Exemplo: Documentos Integrados com o CFOP 1253, que correspondem à Energia Elétrica integrados com Modelo de Documento 55 sendo que o Registro C500 aceita Modelos de Energia Elétrica ( 06, 28, 29) \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	5.00	2	0
29	1	5	22	5	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Emitir o Relatório Conferência do Apuração de Pis/Cofins  \\n >>[Nick]:Caminho do Relatório: Fiscal/ Processos/ Apuração de Pis/Cofins/ Conferência do Apuração de Pis/Cofins. Usar os Filtros: CST e Natureza da Base do Cálculo do Crédito.Em  Tipo de Relatório", selecionar a opção "Sintético por Documento". Em "CST", selecione "Entradas", e selecione os CSTs que apresentarem no erro do SPED, Registros M105 e M505. O mesmo procedimento, deve ser realizado para a Natureza da Base de Cálculo do Crédito. Exemplo: Documentos Integrados com o CFOP 1253, que correspondem à Energia Elétrica integrados com Modelo de Documento 55 sendo que o Registro C500 aceita Modelos de Energia Elétrica ( 06, 28, 29) \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	5.00	2	0
30	1	5	22	38	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Emitir o Relatório Conferência do Apuração de Pis/Cofins  \\n >>[Nick]:Caminho do Relatório: Fiscal/ Processos/ Apuração de Pis/Cofins/ Conferência do Apuração de Pis/Cofins. Usar os Filtros: CST e Natureza da Base do Cálculo do Crédito.Em  Tipo de Relatório", selecionar a opção "Sintético por Documento". Em "CST", selecione "Entradas", e selecione os CSTs que apresentarem no erro do SPED, Registros M105 e M505. O mesmo procedimento, deve ser realizado para a Natureza da Base de Cálculo do Crédito. Exemplo: Documentos Integrados com o CFOP 1253, que correspondem à Energia Elétrica integrados com Modelo de Documento 55 sendo que o Registro C500 aceita Modelos de Energia Elétrica ( 06, 28, 29) \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Sem problemas! Tente este: \\n >>[Nick]:Emitir o Apuração de Pis/Cofins \\n >>[Nick]:Emitir o Apuração de Pis/Cofins e conciliar os CST e CFOPS geradores de créditos, com o Relatório de Conferência de Pis/Cofins \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	2.00	2	1
31	2	5	22	5	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Emitir o Relatório Conferência do Apuração de Pis/Cofins  \\n >>[Nick]:Caminho do Relatório: Fiscal/ Processos/ Apuração de Pis/Cofins/ Conferência do Apuração de Pis/Cofins. Usar os Filtros: CST e Natureza da Base do Cálculo do Crédito.Em  Tipo de Relatório", selecionar a opção "Sintético por Documento". Em "CST", selecione "Entradas", e selecione os CSTs que apresentarem no erro do SPED, Registros M105 e M505. O mesmo procedimento, deve ser realizado para a Natureza da Base de Cálculo do Crédito. Exemplo: Documentos Integrados com o CFOP 1253, que correspondem à Energia Elétrica integrados com Modelo de Documento 55 sendo que o Registro C500 aceita Modelos de Energia Elétrica ( 06, 28, 29) \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	4.00	2	0
32	1	5	22	5	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Emitir o Relatório Conferência do Apuração de Pis/Cofins  \\n >>[Nick]:Caminho do Relatório: Fiscal/ Processos/ Apuração de Pis/Cofins/ Conferência do Apuração de Pis/Cofins. Usar os Filtros: CST e Natureza da Base do Cálculo do Crédito.Em  Tipo de Relatório", selecionar a opção "Sintético por Documento". Em "CST", selecione "Entradas", e selecione os CSTs que apresentarem no erro do SPED, Registros M105 e M505. O mesmo procedimento, deve ser realizado para a Natureza da Base de Cálculo do Crédito. Exemplo: Documentos Integrados com o CFOP 1253, que correspondem à Energia Elétrica integrados com Modelo de Documento 55 sendo que o Registro C500 aceita Modelos de Energia Elétrica ( 06, 28, 29) \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	3.00	2	0
33	1	5	22	6	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, DIVERGÊNCIAS NOS REGISTROS M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:NÃO \\n >>[Nick]:Sem Problemas! Escolha outra opção. \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, ERRO DE ESTRUTURA ÁRVORE é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Emitir a Conferência do Apuração de Pis/Cofins \\n >>[Nick]:Imprima o Apuração de Pis/Cofins (Módulo: Fiscal, Aba: Processos, Apuração de Pis/Cofins) e confiram as alíquotas de acordo com o Regime de sua Empresa.  \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Infelizmente ainda não consegui resolver seu problema e não tenho mais ideias. Mas tudo bem. Vou anotar seu chamado para um atendente. Na próxima estarei mais esperto	N	4.00	1	2
34	1	5	22	14	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:NÃO \\n >>[Nick]:Sem Problemas! Escolha outra opção. \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, DIVERGÊNCIAS NOS REGISTROS M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Já verificou o parâmetro dinâmico  Import_Docs_Processados"? \\n >>[Nick]:Esse parâmetro determina se o módulo irá importar os documentos fiscais vindos do módulo de entrada, para que esses documentos sejam processados o parâmetro deve ter o valor  S". Onde verifica: Módulo Fiscal -> Configuração -> Empresa -> Parâmetro Dinâmico -> Digite o nome do parâmetro e pressione F8. \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Sem problemas! Tente este: \\n >>[Nick]:Foi verificado se o CGO está ajustado para permitir a importação? \\n >>[Nick]:O CGO possui um parâmetro que determina de quais as origens permitidas para importação de documentos. Onde verifica: Módulo Parâmetros -> Configuração -> CGO -> Aba Fiscal -> Parâmetro Doc. Origens, ajuste para permitir documentos vindos do SM e pressione o botão atualizar. \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	4.00	2	2
35	1	5	22	6	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, ERRO DE ESTRUTURA ÁRVORE é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Emitir a Conferência do Apuração de Pis/Cofins \\n >>[Nick]:Imprima o Apuração de Pis/Cofins (Módulo: Fiscal, Aba: Processos, Apuração de Pis/Cofins) e confiram as alíquotas de acordo com o Regime de sua Empresa.  \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Infelizmente ainda não consegui resolver seu problema e não tenho mais ideias. Mas tudo bem. Vou anotar seu chamado para um atendente. Na próxima estarei mais esperto	N	5.00	1	1
36	1	5	22	15	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:NÃO \\n >>[Nick]:Sem Problemas! Escolha outra opção. \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, DIVERGÊNCIAS NOS REGISTROS M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Foi verificado se o CGO está ajustado para permitir a importação? \\n >>[Nick]:O CGO possui um parâmetro que determina de quais as origens permitidas para importação de documentos. Onde verifica: Módulo Parâmetros -> Configuração -> CGO -> Aba Fiscal -> Parâmetro Doc. Origens, ajuste para permitir documentos vindos do SM e pressione o botão atualizar. \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Sem problemas! Tente este: \\n >>[Nick]:Já verificou o parâmetro dinâmico  Import_Docs_Processados"? \\n >>[Nick]:Esse parâmetro determina se o módulo irá importar os documentos fiscais vindos do módulo de entrada, para que esses documentos sejam processados o parâmetro deve ter o valor  S". Onde verifica: Módulo Fiscal -> Configuração -> Empresa -> Parâmetro Dinâmico -> Digite o nome do parâmetro e pressione F8. \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Infelizmente ainda não consegui resolver seu problema e não tenho mais ideias. Mas tudo bem. Vou anotar seu chamado para um atendente. Na próxima estarei mais esperto	N	4.00	1	3
37	1	5	22	15	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, DIVERGÊNCIAS NOS REGISTROS M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Foi verificado se o CGO está ajustado para permitir a importação? \\n >>[Nick]:O CGO possui um parâmetro que determina de quais as origens permitidas para importação de documentos. Onde verifica: Módulo Parâmetros -> Configuração -> CGO -> Aba Fiscal -> Parâmetro Doc. Origens, ajuste para permitir documentos vindos do SM e pressione o botão atualizar. \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Sem problemas! Tente este: \\n >>[Nick]:Já verificou o parâmetro dinâmico  Import_Docs_Processados"? \\n >>[Nick]:Esse parâmetro determina se o módulo irá importar os documentos fiscais vindos do módulo de entrada, para que esses documentos sejam processados o parâmetro deve ter o valor  S". Onde verifica: Módulo Fiscal -> Configuração -> Empresa -> Parâmetro Dinâmico -> Digite o nome do parâmetro e pressione F8. \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	5.00	2	1
38	1	5	22	6	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, ERRO DE ESTRUTURA ÁRVORE é  o que está ocorrendo? Responda. \\n >>[Nick]:Certo, ERRO DE ESTRUTURA ÁRVORE é  o que está ocorrendo? Responda. \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, TESTE é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Emitir a Conferência do Apuração de Pis/Cofins \\n >>[Nick]:Imprima o Apuração de Pis/Cofins (Módulo: Fiscal, Aba: Processos, Apuração de Pis/Cofins) e confiram as alíquotas de acordo com o Regime de sua Empresa.  \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	5.00	2	0
39	1	5	22	5	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Emitir o Relatório Conferência do Apuração de Pis/Cofins  \\n >>[Nick]:Caminho do Relatório: Fiscal/ Processos/ Apuração de Pis/Cofins/ Conferência do Apuração de Pis/Cofins. Usar os Filtros: CST e Natureza da Base do Cálculo do Crédito.Em  Tipo de Relatório", selecionar a opção "Sintético por Documento". Em "CST", selecione "Entradas", e selecione os CSTs que apresentarem no erro do SPED, Registros M105 e M505. O mesmo procedimento, deve ser realizado para a Natureza da Base de Cálculo do Crédito. Exemplo: Documentos Integrados com o CFOP 1253, que correspondem à Energia Elétrica integrados com Modelo de Documento 55 sendo que o Registro C500 aceita Modelos de Energia Elétrica ( 06, 28, 29) \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	5.00	2	0
41	1	5	22	15	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, DIVERGÊNCIAS NOS REGISTROS M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Já verificou o parâmetro dinâmico  Import_Docs_Processados"? \\n >>[Nick]:Esse parâmetro determina se o módulo irá importar os documentos fiscais vindos do módulo de entrada, para que esses documentos sejam processados o parâmetro deve ter o valor  S". Onde verifica: Módulo Fiscal -> Configuração -> Empresa -> Parâmetro Dinâmico -> Digite o nome do parâmetro e pressione F8. \\n   **[User]:SIM \\n   **[User]:Questão Resolvida! \\n >>[Nick]:Que bom! Fico contente! Agora por favor, avalie nosso atendimento.	S	5.00	2	0
42	1	5	22	14	 \\n >>[Nick]:Olá eu sou o Nickolas! \\n >>[Nick]:Para ACRUX FISCI - FISCAL, FIS00046, conheço os incidentes ao lado. Clique para uma descrição.  \\n >>[Nick]:Certo, VALOR DO APURAÇÃO DE PIS/COFINS DEMONSTRADO NO REGISTRO M105/M505 é  o que está ocorrendo? Responda. \\n >>[Nick]:Ooops... vi que você mudou de escolha. Tudo bem. \\n >>[Nick]:Certo, DIVERGÊNCIAS NOS REGISTROS M105/M505 é  o que está ocorrendo? Responda. \\n   **[User]:SIM \\n >>[Nick]:Entendi! Já verificou o parâmetro dinâmico  Import_Docs_Processados"? \\n >>[Nick]:Esse parâmetro determina se o módulo irá importar os documentos fiscais vindos do módulo de entrada, para que esses documentos sejam processados o parâmetro deve ter o valor  S". Onde verifica: Módulo Fiscal -> Configuração -> Empresa -> Parâmetro Dinâmico -> Digite o nome do parâmetro e pressione F8. \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Sem problemas! Tente este: \\n >>[Nick]:Foi verificado se o CGO está ajustado para permitir a importação? \\n >>[Nick]:O CGO possui um parâmetro que determina de quais as origens permitidas para importação de documentos. Onde verifica: Módulo Parâmetros -> Configuração -> CGO -> Aba Fiscal -> Parâmetro Doc. Origens, ajuste para permitir documentos vindos do SM e pressione o botão atualizar. \\n   **[User]:NÃO \\n   **[User]:Ainda não resolvi \\n >>[Nick]:Infelizmente ainda não consegui resolver seu problema e não tenho mais ideias. Mas tudo bem. Vou anotar seu chamado para um atendente. Na próxima estarei mais esperto	N	1.00	1	2
\.


--
-- Name: rating_seq_rating_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('rating_seq_rating_seq', 42, true);


--
-- Data for Name: sugestao; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY sugestao (seq_sugestao, descricao, detalhes) FROM stdin;
3	Necessário aplicação de ajuste técnico na aplicação.	Após ser direcionado á consultora, será realizado o procedimento necessário para ajustar a aplicação com ajustes da empresa na base de dados e aplicação.
9	Emitir o Relatório Conferência do Apuração de Pis/Cofins Outro outro outro	Caminho do Relatório: Fiscal/ Processos/ Apuração de Pis/Cofins/ Conferência do Apuração de Pis/Cofins. Em "CST", selecione "Entradas", e selecione os CSTs que forem geradores de Crédito de Pis/Cofins (Exemplo: 50, 53). Em "Tipo de Relatório", selecionar a opção "Resumo por Nat. Base Cred. e CST" e localiza o CST com a divergência. Após idenfiticado o CST com divergência, emita novamente o Relatório, agora, utilizando os filtros: em "CST", selecione "Entradas", e selecione os CSTs que foi identificado no Relatório anterior, em "Tipo de Relatório", selecionar a opção "Sintético por Documento". Em seguida, localizar o movimento que estiver com Natureza da Base de Cálculo do Crédito nula. Através do Relatório identifique o Documento, corrija-o e faça ao procedimento de Recomposição do Apuração (caminho: Através da Empresa Matriz, acessar: Fiscal/Processos/Apuração de Pis/Cofins/Apuração de Pis/Cofins/Demonstrar e Imprimir Dados Consolidados/Recompor Apuração
57	Erro SQL  para o registro 0150	Situação solucionada pelo requisito 173670 que está liberado nas versões 17.01.160 PTF 17.01-215 (Ômega) e 18.01.011 PTF 18.01-011 (Delta).  Por gentileza, atualize a versão para correção do seu problema.
6	Emitir o Relatório Conferência do Apuração de Pis/Cofins 	Caminho do Relatório: Fiscal/ Processos/ Apuração de Pis/Cofins/ Conferência do Apuração de Pis/Cofins. Usar os Filtros: CST e Natureza da Base do Cálculo do Crédito.Em "Tipo de Relatório", selecionar a opção "Sintético por Documento". Em "CST", selecione "Entradas", e selecione os CSTs que apresentarem no erro do SPED, Registros M105 e M505. O mesmo procedimento, deve ser realizado para a Natureza da Base de Cálculo do Crédito. Exemplo: Documentos Integrados com o CFOP 1253, que correspondem à Energia Elétrica integrados com Modelo de Documento 55 sendo que o Registro C500 aceita Modelos de Energia Elétrica ( 06, 28, 29)
58	Emitir o Apuração de Pis/Cofins	Emitir o Apuração de Pis/Cofins e conciliar os CST e CFOPS geradores de créditos, com o Relatório de Conferência de Pis/Cofins
59	Emitir o Relatório Operações e Prestações por UF	Emitir o Relatório de Operações e Prestações por UF. Módulo: Fiscal, Aba: Relatórios, Relatório: Operações e Prestações por UF. Informe o período e gere o relatório.\nConfira os valores, categorizando por CFOP, com o Apuração de Pis/Cofins
8	Emitir a Conferência do Apuração de Pis/Cofins	Imprima o Apuração de Pis/Cofins (Módulo: Fiscal, Aba: Processos, Apuração de Pis/Cofins) e confiram as alíquotas de acordo com o Regime de sua Empresa. 
1	Já verificou o parâmetro dinâmico "Import_Docs_Processados"?	Esse parâmetro determina se o módulo irá importar os documentos fiscais vindos do módulo de entrada, para que esses documentos sejam processados o parâmetro deve ter o valor "S". Onde verifica: Módulo Fiscal -> Configuração -> Empresa -> Parâmetro Dinâmico -> Digite o nome do parâmetro e pressione F8.
2	Foi verificado se o CGO está ajustado para permitir a importação?	O CGO possui um parâmetro que determina de quais as origens permitidas para importação de documentos. Onde verifica: Módulo Parâmetros -> Configuração -> CGO -> Aba Fiscal -> Parâmetro Doc. Origens, ajuste para permitir documentos vindos do SM e pressione o botão atualizar.
45	Troca de layout	Após disponibilização da SEFAZ, se fez necessário a alteração do layout para a versão 12.1. Acesse o Fiscal, Manutenção, ...
46	Erro SQL para o registro 0150	Ao gerar o arquivo SPED Contribuições para o mês 12 irá apresentar erro SQL.\nEstá situação foi corrigida pelo RC 173670 está liberado nas versões 17.01.160 PTF 17.01-215 (Ômega) e 18.01.011 PTF 18.01-0151(Delta).
\.


--
-- Data for Name: sugestao_erro; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY sugestao_erro (seq_sugestao_erro, seq_erro, seq_sugestao, ocorrencia, relevancia, contorno) FROM stdin;
5	4	6	5	1	0
38	4	58	0	0	0
7	6	9	0	0	0
39	4	59	0	0	0
6	5	8	3	1	0
34	6	45	0	0	0
15	3	1	2	1	0
14	3	2	1	0	0
37	26	57	0	0	173670
1	2	1	4	0	0
3	2	3	10	0.545454562	175000
2	2	2	15	1	0
\.


--
-- Name: sugestao_erro_seq_sugestao_erro_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('sugestao_erro_seq_sugestao_erro_seq', 39, true);


--
-- Name: sugestao_seq_sugestao_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('sugestao_seq_sugestao_seq', 59, true);


--
-- Data for Name: teste; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY teste (id, name) FROM stdin;
1	Teste1
2	Teste2
3	Teste3
4	Teste3
5	Teste3
6	Teste4
7	Teste5
8	Teste6
9	Teste7
10	Teste8
11	Teste9
12	Teste0
13	Teste10
14	Teste10000
15	Teste10000
\.


--
-- Name: teste_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('teste_id_seq', 15, true);


--
-- Name: aplicacao aplicacao_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY aplicacao
    ADD CONSTRAINT aplicacao_unique UNIQUE (aplicacao, descricao);


--
-- Name: erro erro_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY erro
    ADD CONSTRAINT erro_unique UNIQUE (titulo, tags);


--
-- Name: modulo modulo_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY modulo
    ADD CONSTRAINT modulo_unique UNIQUE (modulo, sigla, descricao);


--
-- Name: ptf_modulo ptf_modulo_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ptf_modulo
    ADD CONSTRAINT ptf_modulo_unique UNIQUE (seq_ptf, seq_modulo);


--
-- Name: ptf ptf_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ptf
    ADD CONSTRAINT ptf_unique UNIQUE (versao, sprint, release);


--
-- Name: rating rating_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY rating
    ADD CONSTRAINT rating_pkey PRIMARY KEY (seq_rating);


--
-- Name: anexo seqanexo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY anexo
    ADD CONSTRAINT seqanexo PRIMARY KEY (seq_anexo);


--
-- Name: aplicacao seqaplicacao; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY aplicacao
    ADD CONSTRAINT seqaplicacao PRIMARY KEY (seq_aplicacao);


--
-- Name: erro seqerro; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY erro
    ADD CONSTRAINT seqerro PRIMARY KEY (seq_erro);


--
-- Name: modulo seqmodulo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY modulo
    ADD CONSTRAINT seqmodulo PRIMARY KEY (seq_modulo);


--
-- Name: ptf seqptf; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ptf
    ADD CONSTRAINT seqptf PRIMARY KEY (seq_ptf);


--
-- Name: ptf_modulo seqptfmodulo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ptf_modulo
    ADD CONSTRAINT seqptfmodulo PRIMARY KEY (seq_ptf_modulo);


--
-- Name: sugestao seqsugestao; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY sugestao
    ADD CONSTRAINT seqsugestao PRIMARY KEY (seq_sugestao);


--
-- Name: sugestao_erro seqsugestaoerro; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY sugestao_erro
    ADD CONSTRAINT seqsugestaoerro PRIMARY KEY (seq_sugestao_erro);


--
-- Name: sugestao sugestao_unique_01; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY sugestao
    ADD CONSTRAINT sugestao_unique_01 UNIQUE (descricao);


--
-- Name: sugestao_erro sugestaoerro_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY sugestao_erro
    ADD CONSTRAINT sugestaoerro_unique UNIQUE (seq_erro, seq_sugestao);


--
-- Name: teste teste_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY teste
    ADD CONSTRAINT teste_pkey PRIMARY KEY (id);


--
-- Name: rating tai_rating; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tai_rating AFTER INSERT ON rating FOR EACH ROW EXECUTE PROCEDURE fun_atualiza_rating_trigger();


--
-- Name: anexo anexo_seq_erro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY anexo
    ADD CONSTRAINT anexo_seq_erro_fkey FOREIGN KEY (seq_erro) REFERENCES erro(seq_erro) ON DELETE CASCADE;


--
-- Name: aplicacao aplicacao_seq_modulo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY aplicacao
    ADD CONSTRAINT aplicacao_seq_modulo_fkey FOREIGN KEY (seq_modulo) REFERENCES modulo(seq_modulo) ON DELETE CASCADE;


--
-- Name: erro erro_seq_aplicacao_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY erro
    ADD CONSTRAINT erro_seq_aplicacao_fkey FOREIGN KEY (seq_aplicacao) REFERENCES aplicacao(seq_aplicacao) ON DELETE CASCADE;


--
-- Name: ptf_modulo ptf_modulo_seq_modulo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ptf_modulo
    ADD CONSTRAINT ptf_modulo_seq_modulo_fkey FOREIGN KEY (seq_modulo) REFERENCES modulo(seq_modulo) ON DELETE CASCADE;


--
-- Name: ptf_modulo ptf_modulo_seq_ptf_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ptf_modulo
    ADD CONSTRAINT ptf_modulo_seq_ptf_fkey FOREIGN KEY (seq_ptf) REFERENCES ptf(seq_ptf) ON DELETE CASCADE;


--
-- Name: rating rating_seq_modulo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY rating
    ADD CONSTRAINT rating_seq_modulo_fkey FOREIGN KEY (seq_modulo) REFERENCES modulo(seq_modulo) ON DELETE CASCADE;


--
-- Name: rating rating_seq_ptf_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY rating
    ADD CONSTRAINT rating_seq_ptf_fkey FOREIGN KEY (seq_ptf) REFERENCES ptf(seq_ptf) ON DELETE CASCADE;


--
-- Name: rating rating_seq_sugestao_erro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY rating
    ADD CONSTRAINT rating_seq_sugestao_erro_fkey FOREIGN KEY (seq_sugestao_erro) REFERENCES sugestao_erro(seq_sugestao_erro) ON DELETE CASCADE;


--
-- Name: sugestao_erro sugestao_erro_seq_erro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY sugestao_erro
    ADD CONSTRAINT sugestao_erro_seq_erro_fkey FOREIGN KEY (seq_erro) REFERENCES erro(seq_erro) ON DELETE CASCADE;


--
-- Name: sugestao_erro sugestao_erro_seq_sugestao_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY sugestao_erro
    ADD CONSTRAINT sugestao_erro_seq_sugestao_fkey FOREIGN KEY (seq_sugestao) REFERENCES sugestao(seq_sugestao) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\connect postgres

SET default_transaction_read_only = off;

--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.5
-- Dumped by pg_dump version 9.6.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: postgres; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON DATABASE postgres IS 'default administrative connection database';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- PostgreSQL database dump complete
--

\connect template1

SET default_transaction_read_only = off;

--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.5
-- Dumped by pg_dump version 9.6.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: template1; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON DATABASE template1 IS 'default template for new databases';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- PostgreSQL database dump complete
--

--
-- PostgreSQL database cluster dump complete
--

