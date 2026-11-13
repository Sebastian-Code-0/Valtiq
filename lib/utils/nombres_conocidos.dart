import 'gasto_rapido.dart';
import 'tipo_deuda.dart';

/// Lista de nombres conocidos en Colombia (bancos, billeteras, tiendas,
/// servicios…) escritos como TEXTO, sin logos: solo sirven para sugerir al
/// escribir y para adivinar la categoría de un gasto la primera vez.
///
/// Cada grupo trae su categoría de gasto por defecto (el nombre de una
/// categoría de fábrica) y el tipo de deuda que le corresponde. Para
/// agregar un nombre basta con sumarlo a su grupo; los [alias] son otras
/// formas en que la gente lo escribe ("bancol", "la rebaja").
class GrupoNombres {
  const GrupoNombres({
    required this.tipo,
    required this.nombres,
    this.categoria,
    this.tipoDeuda = TipoDeuda.otro,
  });

  /// "Banco", "Supermercado"… se muestra junto a la sugerencia.
  final String tipo;
  final List<NombreConocido> nombres;

  /// Categoría de gasto por defecto (null = no adivinar).
  final String? categoria;
  final TipoDeuda tipoDeuda;
}

class NombreConocido {
  const NombreConocido(this.nombre, {this.alias = const [], this.categoria});

  final String nombre;
  final List<String> alias;

  /// Si es distinta a la de su grupo.
  final String? categoria;
}

/// Un nombre ya resuelto, listo para mostrar.
class Sugerencia {
  const Sugerencia(this.nombre, this.grupo);

  final String nombre;
  final GrupoNombres grupo;

  String? get categoria =>
      _porNombre[normalizarNombre(nombre)]?.categoria ?? grupo.categoria;
}

/// Nombre corto para que la lista se lea mejor.
typedef _N = NombreConocido;

const gruposNombres = <GrupoNombres>[
  // ---------------------------------------------------------------- Bancos
  GrupoNombres(
    tipo: 'Banco',
    tipoDeuda: TipoDeuda.banco,
    nombres: [
      _N('Bancolombia', alias: ['bancol', 'bancolombia a la mano']),
      _N('Banco de Bogotá', alias: ['banco bogota', 'bco bogota']),
      _N('Davivienda', alias: ['davi']),
      _N('BBVA', alias: ['bbva colombia']),
      _N('Banco de Occidente', alias: ['occidente']),
      _N('Banco Popular', alias: ['popular']),
      _N('Banco AV Villas', alias: ['av villas', 'avvillas']),
      _N('Banco Caja Social', alias: ['caja social']),
      _N('Banco Agrario', alias: ['agrario']),
      _N('Scotiabank Colpatria', alias: ['colpatria', 'scotiabank']),
      _N('Davibank'),
      _N('Itaú', alias: ['itau']),
      _N('Banco GNB Sudameris', alias: ['gnb sudameris', 'sudameris']),
      _N('Banco Falabella'),
      _N('Banco Pichincha', alias: ['pichincha']),
      _N('Bancoomeva'),
      _N('Banco Finandina', alias: ['finandina']),
      _N('Banco W'),
      _N('Bancamía', alias: ['bancamia']),
      _N('Banco Mundo Mujer', alias: ['mundo mujer']),
      _N('Banco Serfinanza', alias: ['serfinanza']),
      _N('Banco Santander', alias: ['santander']),
      _N('Citibank', alias: ['citi']),
      _N('Banco Coopcentral', alias: ['coopcentral']),
      _N('Banco Contactar', alias: ['contactar']),
      _N('Banco Unión', alias: ['banco union', 'giros y finanzas']),
      _N('Lulo Bank', alias: ['lulo']),
      _N('Nu', alias: ['nubank', 'nu colombia', 'tarjeta nu']),
      _N('Mibanco'),
      _N('Ban100', alias: ['banco 100']),
      _N('Banco Credifinanciera', alias: ['credifinanciera']),
      _N('Coltefinanciera'),
      _N('Pibank'),
      _N('Bancóldex', alias: ['bancoldex']),
      _N('Fondo Nacional del Ahorro', alias: ['fna', 'fondo nacional']),
      _N('ICETEX', alias: ['icetex'], categoria: 'Educación'),
    ],
  ),
  // ------------------------------------------------------ Billeteras y pagos
  GrupoNombres(
    tipo: 'Billetera digital',
    tipoDeuda: TipoDeuda.banco,
    nombres: [
      _N('Nequi'),
      _N('Daviplata', alias: ['davi plata']),
      _N('Movii', alias: ['movi']),
      _N('Dale!', alias: ['dale']),
      _N('Ualá', alias: ['uala']),
      _N('RappiPay', alias: ['rappi pay', 'rappicard', 'rappi card']),
      _N('Mercado Pago', alias: ['mercadopago']),
      _N('PayPal', alias: ['paypal']),
      _N('Global66'),
      _N('Powwi'),
      _N('Tpaga'),
      _N('Bold'),
      _N('Wompi'),
      _N('PSE'),
      _N('Bre-B', alias: ['breb', 'bre b']),
      _N('Transfiya'),
      _N('Littio'),
      _N('Tyba'),
      _N('Trii'),
    ],
  ),
  // ------------------------------------------- Tarjetas de crédito de tiendas
  GrupoNombres(
    tipo: 'Tarjeta de crédito',
    tipoDeuda: TipoDeuda.tarjeta,
    nombres: [
      _N('Tarjeta Éxito', alias: ['tarjeta exito', 'tuya']),
      _N('Tuya'),
      _N('CMR Falabella', alias: ['cmr', 'tarjeta falabella']),
      _N('Tarjeta Alkosto'),
      _N('Tarjeta Olímpica', alias: ['tarjeta olimpica']),
      _N('Tarjeta Cencosud', alias: ['tarjeta jumbo', 'tarjeta metro']),
      _N('Crédito Fácil Codensa', alias: ['credito facil codensa', 'codensa']),
      _N('Tarjeta Flamingo'),
      _N('Tarjeta Makro'),
      _N('Tarjeta Pepe Ganga'),
      _N('Visa'),
      _N('Mastercard', alias: ['master card']),
      _N('American Express', alias: ['amex']),
      _N('Diners Club', alias: ['diners']),
    ],
  ),
  // ------------------------------------------ Financieras y crédito en línea
  GrupoNombres(
    tipo: 'Financiera o crédito',
    tipoDeuda: TipoDeuda.banco,
    nombres: [
      _N('Sistecrédito', alias: ['sistecredito']),
      _N('Addi'),
      _N('Meddipay'),
      _N('Brilla', alias: ['brilla gases']),
      _N('Credivalores'),
      _N('Lineru'),
      _N('RapiCredit', alias: ['rapicredit', 'rapi credit']),
      _N('Kredicity'),
      _N('Juancho Te Presta', alias: ['juancho']),
      _N('Monet'),
      _N('Solventa'),
      _N('Credifamilia'),
      _N('Finsocial'),
      _N('Fincomercio'),
      _N('Kala'),
    ],
  ),
  // ---------------------------------------------------------- Cooperativas
  GrupoNombres(
    tipo: 'Cooperativa',
    tipoDeuda: TipoDeuda.banco,
    nombres: [
      _N('Coomeva'),
      _N('Confiar'),
      _N('Cotrafa'),
      _N('JFK Cooperativa', alias: ['jfk']),
      _N('Cooperativa Financiera de Antioquia', alias: ['cfa']),
      _N('Juriscoop'),
      _N('Coofinep'),
      _N('Comultrasan'),
      _N('Cofincafé', alias: ['cofincafe']),
      _N('Crediservir'),
      _N('Utrahuilca'),
      _N('Coopkennedy'),
      _N('Cootracolta'),
      _N('Coopantex'),
      _N('Microempresas de Colombia'),
      _N('Febor'),
      _N('Fondo de empleados'),
    ],
  ),
  // ------------------------------------------- Cajas de compensación
  GrupoNombres(
    tipo: 'Caja de compensación',
    tipoDeuda: TipoDeuda.banco,
    nombres: [
      _N('Comfama'),
      _N('Comfenalco'),
      _N('Compensar'),
      _N('Colsubsidio'),
      _N('Cafam'),
      _N('Comfandi'),
      _N('Comfacundi'),
      _N('Comfamiliar'),
      _N('Cajasan'),
      _N('Comfaboy'),
      _N('Comfacor'),
      _N('Comfasucre'),
      _N('Comfaguajira'),
      _N('Comfacesar'),
      _N('Comfatolima'),
      _N('Comfamiliar Atlántico', alias: ['comfamiliar atlantico']),
      _N('Combarranquilla'),
      _N('Comfenalco Valle'),
      _N('Comfenalco Antioquia'),
      _N('Comfenalco Santander'),
      _N('Confa'),
      _N('Comfamiliar Risaralda'),
      _N('Comfenalco Quindío', alias: ['comfenalco quindio']),
      _N('Cofrem'),
      _N('Comfaoriente'),
      _N('Comfanorte'),
    ],
  ),
  // ---------------------------------------------------------- Supermercados
  GrupoNombres(
    tipo: 'Supermercado',
    categoria: 'Alimentación',
    tipoDeuda: TipoDeuda.tienda,
    nombres: [
      _N('D1', alias: ['tiendas d1', 'el d1']),
      _N('Ara', alias: ['tiendas ara', 'el ara']),
      _N('Éxito', alias: ['exito', 'almacenes exito']),
      _N('Carulla'),
      _N('Surtimax'),
      _N('Super Inter', alias: ['superinter']),
      _N('Olímpica', alias: ['olimpica', 'sao']),
      _N('Jumbo'),
      _N('Metro', alias: ['supermercado metro']),
      _N('Isimo'),
      _N('Makro'),
      _N('PriceSmart', alias: ['price smart']),
      _N('Colsubsidio Supermercado'),
      _N('Euro', alias: ['euro supermercados']),
      _N('Consumo', alias: ['supermercados consumo']),
      _N('La Vaquita', alias: ['vaquita']),
      _N('Mercaldas'),
      _N('Megatiendas'),
      _N('Mercamío', alias: ['mercamio']),
      _N('Zapatoca', alias: ['supermercados zapatoca']),
      _N('Oxxo'),
      _N('Tiendas 3B', alias: ['3b', 'mercados 3b']),
      _N('Justo & Bueno', alias: ['justo y bueno']),
      _N('Merqueo'),
      _N('Comfandi Supermercado'),
      _N('Supertiendas Cañaveral', alias: ['cañaveral', 'canaveral']),
      _N('Almacenes La 14', alias: ['la 14']),
      _N('Fruver'),
      _N('Plaza de mercado', alias: ['plaza', 'galeria']),
      _N('Tienda de barrio', alias: ['tienda', 'la tienda']),
      _N('Panadería', alias: ['panaderia']),
      _N('Carnicería', alias: ['carniceria', 'famas']),
    ],
  ),
  // ---------------------------------------------- Tiendas y grandes almacenes
  GrupoNombres(
    tipo: 'Tienda',
    tipoDeuda: TipoDeuda.tienda,
    nombres: [
      _N('Alkosto', categoria: 'Tecnología'),
      _N('Ktronix', categoria: 'Tecnología'),
      _N('Alkomprar', categoria: 'Tecnología'),
      _N('Falabella'),
      _N('Homecenter', alias: ['home center', 'sodimac'], categoria: 'Hogar'),
      _N('Easy', categoria: 'Hogar'),
      _N('Constructor', categoria: 'Hogar'),
      _N('Pepe Ganga'),
      _N('Panamericana', categoria: 'Educación'),
      _N('Flamingo'),
      _N('Dollarcity', alias: ['dollar city']),
      _N('Miniso'),
      _N('Mercado Libre', alias: ['mercadolibre', 'meli']),
      _N('Amazon'),
      _N('Temu'),
      _N('Shein', categoria: 'Ropa'),
      _N('AliExpress', alias: ['ali express']),
      _N('Tugó', alias: ['tugo'], categoria: 'Hogar'),
      _N('Muebles Jamar', alias: ['jamar'], categoria: 'Hogar'),
      _N('Home Sentry', categoria: 'Hogar'),
      _N('Casaideas', alias: ['casa ideas'], categoria: 'Hogar'),
      _N('Ofix', categoria: 'Educación'),
      _N('Mac Center', categoria: 'Tecnología'),
      _N('iShop', categoria: 'Tecnología'),
      _N('Apple', categoria: 'Tecnología'),
      _N('Samsung', categoria: 'Tecnología'),
      _N('Xiaomi', categoria: 'Tecnología'),
      _N('Motorola', categoria: 'Tecnología'),
      _N('Unicentro'),
      _N('Andino'),
      _N('Centro comercial', alias: ['cc']),
      _N('Ferretería', alias: ['ferreteria'], categoria: 'Hogar'),
      _N('Papelería', alias: ['papeleria'], categoria: 'Educación'),
      _N('Miscelánea', alias: ['miscelanea']),
    ],
  ),
  // ------------------------------------------------------------ Droguerías
  GrupoNombres(
    tipo: 'Droguería',
    categoria: 'Salud',
    tipoDeuda: TipoDeuda.tienda,
    nombres: [
      _N('Cruz Verde'),
      _N('La Rebaja', alias: ['drogas la rebaja', 'rebaja']),
      _N('Farmatodo'),
      _N('Droguería Cafam', alias: ['drogueria cafam']),
      _N('Droguerías Colsubsidio', alias: ['drogueria colsubsidio']),
      _N('Pasteur', alias: ['drogueria pasteur']),
      _N('Droguería Alemana', alias: ['drogueria alemana']),
      _N('Droguería Inglesa', alias: ['drogueria inglesa']),
      _N('Drogas La Economía', alias: ['la economia']),
      _N('Audifarma'),
      _N('Locatel'),
      _N('Copservir'),
      _N('Droguería', alias: ['drogueria', 'farmacia']),
    ],
  ),
  // ------------------------------------------------------- Ropa y calzado
  GrupoNombres(
    tipo: 'Ropa y calzado',
    categoria: 'Ropa',
    tipoDeuda: TipoDeuda.tienda,
    nombres: [
      _N('Arturo Calle'),
      _N('Studio F'),
      _N('Tennis'),
      _N('Koaj'),
      _N('Pat Primo'),
      _N('Ela'),
      _N('Gef'),
      _N('Punto Blanco'),
      _N('Offcorss'),
      _N('Chevignon'),
      _N('Americanino'),
      _N('Esprit'),
      _N('Naf Naf'),
      _N('Mango'),
      _N('Zara'),
      _N('H&M', alias: ['hym', 'h y m']),
      _N('Bershka'),
      _N('Pull&Bear', alias: ['pull and bear', 'pull bear']),
      _N('Stradivarius'),
      _N('Totto'),
      _N('Vélez', alias: ['velez']),
      _N('Bosi'),
      _N('Spring Step'),
      _N('Bata'),
      _N('Adidas'),
      _N('Nike'),
      _N('Puma'),
      _N('Croydon'),
      _N('Payless'),
      _N('Lili Pink', alias: ['lilipink']),
      _N('Leonisa'),
      _N('Facol'),
      _N('Quest'),
      _N('Seven Seven'),
      _N('Ragged'),
      _N('Rifle'),
      _N('Diesel'),
      _N('Tommy Hilfiger', alias: ['tommy']),
      _N('Lacoste'),
      _N('Forever 21'),
      _N('Brahma', alias: ['botas brahma']),
      _N('Mario Hernández', alias: ['mario hernandez']),
      _N('Atmósfera Sport', alias: ['atmosfera sport']),
      _N('Sportline', alias: ['sport line']),
      _N('Decathlon'),
      _N('Under Armour'),
      _N('Skechers'),
      _N('Crocs'),
      _N('Baby Fresh'),
      _N('Epk'),
    ],
  ),
  // ------------------------------------------------------------ Gasolineras
  GrupoNombres(
    tipo: 'Gasolinera',
    categoria: 'Carro',
    nombres: [
      _N('Terpel'),
      _N('Primax'),
      _N('Texaco'),
      _N('Biomax'),
      _N('Esso'),
      _N('Mobil'),
      _N('Zeuss'),
      _N('Brío', alias: ['brio']),
      _N('Petromil'),
      _N('Gasolinera', alias: ['bomba', 'estacion de servicio']),
    ],
  ),
  // ------------------------------------------------- Celular e internet
  GrupoNombres(
    tipo: 'Celular, internet y TV',
    categoria: 'Servicios públicos',
    tipoDeuda: TipoDeuda.otro,
    nombres: [
      _N('Claro'),
      _N('Movistar'),
      _N('Tigo', alias: ['tigo une', 'une']),
      _N('WOM'),
      _N('ETB'),
      _N('Virgin Mobile', alias: ['virgin']),
      _N('Móvil Éxito', alias: ['movil exito']),
      _N('Flash Mobile', alias: ['flash']),
      _N('Kalley Móvil', alias: ['kalley movil']),
      _N('DirecTV', alias: ['directv', 'direct tv']),
      _N('SimpleTV', alias: ['simple tv']),
      _N('Hughesnet'),
      _N('Starlink'),
      _N('Azteca Comunicaciones'),
      _N('Emcali Telecomunicaciones'),
      _N('Recarga', alias: ['recarga celular', 'minutos', 'plan celular']),
    ],
  ),
  // ---------------------------------------- Servicios públicos (por ciudad)
  GrupoNombres(
    tipo: 'Servicios públicos',
    categoria: 'Servicios públicos',
    nombres: [
      // Energía
      _N('EPM', alias: ['empresas publicas de medellin']),
      _N('Enel', alias: ['enel codensa', 'codensa luz']),
      _N('Air-e', alias: ['aire', 'air e']),
      _N('Afinia'),
      _N('Celsia'),
      _N('Emcali'),
      _N('Essa', alias: ['electrificadora de santander']),
      _N('CHEC'),
      _N('EDEQ'),
      _N('Energía de Pereira', alias: ['energia de pereira']),
      _N('CENS'),
      _N('Electrohuila'),
      _N('EMSA'),
      _N('Enerca'),
      _N('Cedenar'),
      _N('Electrocaquetá', alias: ['electrocaqueta']),
      _N('EBSA'),
      _N('Enelar'),
      _N('Electricaribe'),
      _N('Dispac'),
      // Gas
      _N('Vanti', alias: ['gas natural']),
      _N('Gases del Caribe'),
      _N('Gases de Occidente'),
      _N('Efigas'),
      _N('Surtigas'),
      _N('Alcanos'),
      _N('Madigas'),
      _N('Llanogas'),
      _N('Gases del Cusiana'),
      // Agua
      _N(
        'Acueducto de Bogotá',
        alias: ['acueducto bogota', 'eaab', 'eaab-esp'],
      ),
      _N('Triple A', alias: ['aaa']),
      _N('Aguas de Cartagena', alias: ['acuacar']),
      _N('Acueducto de Bucaramanga', alias: ['amb']),
      _N('Aguas de Manizales'),
      _N('Aguas y Aguas de Pereira', alias: ['aguas y aguas']),
      _N('EPA Armenia', alias: ['empresas publicas de armenia']),
      _N('Essmar'),
      _N('Empopasto'),
      _N('Aguas de Barrancabermeja'),
      _N('Acueducto', alias: ['recibo del agua']),
      // Aseo
      _N('Promoambiental'),
      _N('Lime'),
      _N('Ciudad Limpia'),
      _N('Bogotá Limpia', alias: ['bogota limpia']),
      _N('Área Limpia', alias: ['area limpia']),
      _N('Emvarias'),
      _N('Veolia'),
      _N('Interaseo'),
      _N('Promoaseo'),
      _N('Aseo'),
      // Otros del hogar
      _N(
        'Administración',
        alias: ['administracion', 'admin'],
        categoria: 'Hogar',
      ),
      _N('Arriendo', alias: ['arrendamiento', 'renta'], categoria: 'Hogar'),
    ],
  ),
  // ------------------------------------------------------------ Transporte
  GrupoNombres(
    tipo: 'Transporte',
    categoria: 'Transporte',
    nombres: [
      _N('Uber'),
      _N('DiDi', alias: ['didi']),
      _N('Cabify'),
      _N('InDrive', alias: ['indriver', 'in drive']),
      _N('Picap'),
      _N('TransMilenio', alias: ['transmilenio', 'tm']),
      _N('SITP'),
      _N('Tu Llave', alias: ['tullave']),
      _N('Metro de Medellín', alias: ['metro medellin']),
      _N('Cívica', alias: ['civica']),
      _N('MIO', alias: ['mio cali']),
      _N('Megabús', alias: ['megabus']),
      _N('Transcaribe'),
      _N('Metrolínea', alias: ['metrolinea']),
      _N('Transmetro'),
      _N('Metroplús', alias: ['metroplus']),
      _N('Metrocable'),
      _N('Tembici'),
      _N('EnCicla', alias: ['encicla']),
      _N('Bus', alias: ['buseta', 'pasaje', 'colectivo']),
      _N('Taxi'),
      _N('Mototaxi'),
      _N('Flypass', alias: ['fly pass'], categoria: 'Carro'),
      _N('Gopass', alias: ['go pass'], categoria: 'Carro'),
      _N('Facilpass', alias: ['facil pass'], categoria: 'Carro'),
      _N('Peaje', categoria: 'Carro'),
      _N('City Parking', categoria: 'Carro'),
      _N('Parqueadero', alias: ['parqueo'], categoria: 'Carro'),
      _N('SOAT', categoria: 'Carro'),
      _N(
        'Revisión técnico-mecánica',
        alias: ['tecnomecanica', 'revision tecnomecanica'],
        categoria: 'Carro',
      ),
      _N('Lavadero', alias: ['lavado', 'lavautos'], categoria: 'Carro'),
      _N('Taller', alias: ['mecanico'], categoria: 'Carro'),
    ],
  ),
  // ---------------------------------------------------- Viajes y aerolíneas
  GrupoNombres(
    tipo: 'Viajes',
    categoria: 'Viajes',
    nombres: [
      _N('Avianca'),
      _N('Latam'),
      _N('Wingo'),
      _N('Satena'),
      _N('Clic', alias: ['easyfly']),
      _N('JetSMART', alias: ['jetsmart', 'jet smart']),
      _N('Copa Airlines', alias: ['copa']),
      _N('Expreso Bolivariano', alias: ['bolivariano']),
      _N('Expreso Brasilia', alias: ['brasilia']),
      _N('Copetran'),
      _N('Rápido Ochoa', alias: ['rapido ochoa']),
      _N('Coomotor'),
      _N('Flota Magdalena'),
      _N('Berlinas del Fonce', alias: ['berlinas']),
      _N('Expreso Palmira'),
      _N('Booking'),
      _N('Airbnb'),
      _N('Despegar'),
      _N('Decameron'),
      _N('Hotel'),
      _N('Terminal de transporte', alias: ['terminal']),
    ],
  ),
  // ------------------------------------------------ Plataformas y suscripciones
  GrupoNombres(
    tipo: 'Suscripción',
    categoria: 'Suscripciones',
    nombres: [
      _N('Netflix'),
      _N('Disney+', alias: ['disney plus', 'disney']),
      _N('Max', alias: ['hbo max', 'hbo']),
      _N('Prime Video', alias: ['amazon prime', 'prime']),
      _N('Spotify'),
      _N('YouTube Premium', alias: ['youtube']),
      _N('Apple Music'),
      _N('Apple TV+', alias: ['apple tv']),
      _N('iCloud', alias: ['icloud']),
      _N('Google One'),
      _N('Paramount+', alias: ['paramount']),
      _N('Crunchyroll'),
      _N('Deezer'),
      _N('ViX', alias: ['vix']),
      _N('Win Sports+', alias: ['win sports', 'win']),
      _N('DGO', alias: ['directv go']),
      _N('Claro Video'),
      _N('Movistar TV'),
      _N('Xbox Game Pass', alias: ['game pass']),
      _N('PlayStation Plus', alias: ['ps plus']),
      _N('Nintendo Switch Online'),
      _N('Steam', categoria: 'Entretenimiento'),
      _N('ChatGPT', alias: ['chat gpt', 'openai']),
      _N('Claude'),
      _N('Canva'),
      _N('Microsoft 365', alias: ['office 365', 'office']),
      _N('Duolingo'),
      _N('Tinder'),
      _N('Bumble'),
      _N('Platzi', categoria: 'Educación'),
      _N('Coursera', categoria: 'Educación'),
      _N('Udemy', categoria: 'Educación'),
      _N('Smart Fit', alias: ['smartfit']),
      _N('Bodytech', alias: ['body tech']),
      _N('Spinning Center'),
      _N('Gimnasio', alias: ['gym']),
    ],
  ),
  // ------------------------------------------- Restaurantes y domicilios
  GrupoNombres(
    tipo: 'Restaurante o domicilio',
    categoria: 'Restaurantes',
    nombres: [
      _N('Rappi'),
      _N('DiDi Food', alias: ['didi food']),
      _N('iFood', alias: ['ifood']),
      _N('Juan Valdez'),
      _N('Starbucks'),
      _N("Tostao'", alias: ['tostao']),
      _N('Oma'),
      _N('Crepes & Waffles', alias: ['crepes', 'crepes y waffles']),
      _N('El Corral', alias: ['hamburguesas el corral', 'corral']),
      _N("McDonald's", alias: ['mcdonalds', 'mc donalds', 'mc']),
      _N('Burger King'),
      _N('KFC'),
      _N('Frisby'),
      _N('Presto'),
      _N('Subway'),
      _N("Domino's", alias: ['dominos']),
      _N("Papa John's", alias: ['papa johns']),
      _N("Jeno's Pizza", alias: ['jenos', 'jenos pizza']),
      _N('Kokoriko'),
      _N('Sándwich Qbano', alias: ['sandwich qbano', 'qbano']),
      _N("Dunkin'", alias: ['dunkin']),
      _N("Pan Pa' Ya!", alias: ['pan pa ya']),
      _N('Home Burgers'),
      _N("Archie's", alias: ['archies']),
      _N('Wok'),
      _N('Andrés Carne de Res', alias: ['andres carne de res', 'andres']),
      _N('Popsy'),
      _N("Mimo's", alias: ['mimos']),
      _N('Cream Helado'),
      _N('Buffalo Wings'),
      _N("Carl's Jr.", alias: ['carls jr']),
      _N('Taco Bell'),
      _N('Little Caesars'),
      _N('Brasa Roja'),
      _N('Corral Gourmet'),
      _N('Restaurante', alias: ['corrientazo', 'almuerzo ejecutivo']),
    ],
  ),
  // -------------------------------------------- Salud: EPS, clínicas, ópticas
  GrupoNombres(
    tipo: 'Salud',
    categoria: 'Salud',
    nombres: [
      _N('EPS Sura', alias: ['sura eps']),
      _N('Sanitas', alias: ['eps sanitas']),
      _N('Compensar EPS'),
      _N('Nueva EPS'),
      _N('Salud Total'),
      _N('Famisanar'),
      _N('Coosalud'),
      _N('Mutual Ser'),
      _N('Colsanitas'),
      _N('Medisanitas'),
      _N('Coomeva Medicina Prepagada', alias: ['coomeva prepagada']),
      _N('Colmédica', alias: ['colmedica']),
      _N('Emssanar'),
      _N('Aliansalud'),
      _N('Savia Salud'),
      _N('Capresoca'),
      _N('Sura Medicina Prepagada', alias: ['prepagada sura']),
      _N('Allianz Salud'),
      _N('Synlab'),
      _N('Colcan'),
      _N('Lafam', alias: ['opticas lafam']),
      _N('Óptica Alemana', alias: ['optica alemana']),
      _N('GMO', alias: ['opticas gmo']),
      _N('Odontología', alias: ['odontologo', 'dentista']),
      _N('Cita médica', alias: ['cita medica', 'consulta', 'medico']),
      _N('Exámenes', alias: ['examenes', 'laboratorio']),
    ],
  ),
  // ---------------------------------------- Seguros y pensiones
  GrupoNombres(
    tipo: 'Seguros y pensiones',
    categoria: 'Otros',
    nombres: [
      _N('Seguros Bolívar', alias: ['seguros bolivar', 'bolivar']),
      _N('Seguros Sura', alias: ['sura']),
      _N('Allianz'),
      _N('Mapfre'),
      _N('AXA Colpatria', alias: ['axa']),
      _N('HDI Seguros', alias: ['hdi', 'liberty']),
      _N('Seguros del Estado'),
      _N('La Previsora', alias: ['previsora']),
      _N('La Equidad', alias: ['equidad seguros']),
      _N('SBS Seguros', alias: ['sbs']),
      _N('Positiva'),
      _N('Porvenir'),
      _N('Protección', alias: ['proteccion']),
      _N('Colfondos'),
      _N('Skandia'),
      _N('Colpensiones'),
      _N('Seguro', alias: ['poliza']),
    ],
  ),
  // ---------------------------------------- Belleza y cuidado personal
  GrupoNombres(
    tipo: 'Belleza y cuidado personal',
    categoria: 'Cuidado personal',
    tipoDeuda: TipoDeuda.tienda,
    nombres: [
      _N('Natura'),
      _N('Ésika', alias: ['esika']),
      _N('Yanbal'),
      _N("L'Bel", alias: ['lbel', 'l bel']),
      _N('Cyzone'),
      _N('Avon'),
      _N('Fedco'),
      _N('MAC'),
      _N('Jolie de Vogue', alias: ['jolie']),
      _N('Prebel'),
      _N(
        'Peluquería',
        alias: ['peluqueria', 'corte de pelo', 'barberia', 'barbero'],
      ),
      _N('Uñas', alias: ['unas', 'manicure', 'pedicure']),
      _N('Spa'),
    ],
  ),
  // ------------------------------------------------------------- Mascotas
  GrupoNombres(
    tipo: 'Mascotas',
    categoria: 'Mascotas',
    nombres: [
      _N('Puppis'),
      _N('Agrocampo'),
      _N('Laika'),
      _N('Pet Shop', alias: ['petshop']),
      _N('Veterinaria', alias: ['veterinario', 'vet']),
      _N('Concentrado', alias: ['purina', 'dog chow', 'cuido']),
    ],
  ),
  // ----------------------------------------------- Apuestas, giros y pagos
  GrupoNombres(
    tipo: 'Giros, pagos y apuestas',
    categoria: 'Otros',
    nombres: [
      _N('Efecty'),
      _N('SuperGIROS', alias: ['supergiros', 'super giros']),
      _N('Matrix Giros', alias: ['matrix']),
      _N('Western Union'),
      _N('Su Red', alias: ['sured']),
      _N('Gana', alias: ['gana chance']),
      _N('Pagatodo', alias: ['paga todo']),
      _N('Baloto', categoria: 'Entretenimiento'),
      _N('Wplay', categoria: 'Entretenimiento'),
      _N('BetPlay', alias: ['bet play'], categoria: 'Entretenimiento'),
      _N('Rushbet', categoria: 'Entretenimiento'),
      _N('Codere', categoria: 'Entretenimiento'),
      _N('Lotería', alias: ['loteria', 'chance'], categoria: 'Entretenimiento'),
      _N('DIAN', alias: ['impuestos', 'renta dian']),
      _N('Predial', alias: ['impuesto predial'], categoria: 'Hogar'),
    ],
  ),
  // ---------------------------------------------------- Entretenimiento
  GrupoNombres(
    tipo: 'Entretenimiento',
    categoria: 'Entretenimiento',
    nombres: [
      _N('Cine Colombia', alias: ['cine']),
      _N('Cinemark'),
      _N('Procinal'),
      _N('Royal Films'),
      _N('Cinépolis', alias: ['cinepolis']),
      _N('Tuboleta'),
      _N('Eticket'),
      _N('Mundo Aventura'),
      _N('Parque del Café', alias: ['parque del cafe']),
      _N('Salitre Mágico', alias: ['salitre magico']),
      _N('Divercity'),
      _N('Bolera', alias: ['bolos']),
      _N('Discoteca', alias: ['rumba', 'fiesta']),
      _N('Concierto'),
    ],
  ),
];

/// Palabras sueltas del día a día con su categoría ("café 5000"). Van
/// sin tildes y en minúscula; se comparan con [normalizarNombre].
const palabrasCategoria = <String, String>{
  // Alimentación (mercado y comida para la casa)
  'mercado': 'Alimentación',
  'pan': 'Alimentación',
  'leche': 'Alimentación',
  'huevos': 'Alimentación',
  'arroz': 'Alimentación',
  'frutas': 'Alimentación',
  'fruta': 'Alimentación',
  'verduras': 'Alimentación',
  'carne': 'Alimentación',
  'pollo': 'Alimentación',
  'queso': 'Alimentación',
  'arepas': 'Alimentación',
  'mecato': 'Alimentación',
  'agua': 'Alimentación',
  'gaseosa': 'Alimentación',
  'remesa': 'Alimentación',
  // Restaurantes (comer por fuera)
  'cafe': 'Restaurantes',
  'tinto': 'Restaurantes',
  'almuerzo': 'Restaurantes',
  'desayuno': 'Restaurantes',
  'cena': 'Restaurantes',
  'comida': 'Restaurantes',
  'onces': 'Restaurantes',
  'empanada': 'Restaurantes',
  'empanadas': 'Restaurantes',
  'pizza': 'Restaurantes',
  'hamburguesa': 'Restaurantes',
  'salchipapa': 'Restaurantes',
  'helado': 'Restaurantes',
  'domicilio': 'Restaurantes',
  'pandebono': 'Restaurantes',
  'bunuelo': 'Restaurantes',
  'jugo': 'Restaurantes',
  // Transporte
  'bus': 'Transporte',
  'pasaje': 'Transporte',
  'pasajes': 'Transporte',
  'taxi': 'Transporte',
  'metro': 'Transporte',
  'colectivo': 'Transporte',
  'buseta': 'Transporte',
  'transporte': 'Transporte',
  // Carro y moto
  'gasolina': 'Carro',
  'tanqueo': 'Carro',
  'tanquear': 'Carro',
  'acpm': 'Carro',
  'peaje': 'Carro',
  'parqueadero': 'Carro',
  'soat': 'Carro',
  'llantas': 'Carro',
  'aceite': 'Carro',
  'moto': 'Moto',
  'casco': 'Moto',
  // Hogar
  'arriendo': 'Hogar',
  'aseo': 'Hogar',
  'detergente': 'Hogar',
  'jabon': 'Hogar',
  'papel': 'Hogar',
  'bombillo': 'Hogar',
  'muebles': 'Hogar',
  // Servicios públicos
  'luz': 'Servicios públicos',
  'energia': 'Servicios públicos',
  'gas': 'Servicios públicos',
  'internet': 'Servicios públicos',
  'recarga': 'Servicios públicos',
  // Salud
  'drogueria': 'Salud',
  'medicamentos': 'Salud',
  'pastillas': 'Salud',
  'cita': 'Salud',
  'copago': 'Salud',
  'odontologo': 'Salud',
  'gafas': 'Salud',
  // Cuidado personal
  'peluqueria': 'Cuidado personal',
  'corte': 'Cuidado personal',
  'barberia': 'Cuidado personal',
  'unas': 'Cuidado personal',
  'shampoo': 'Cuidado personal',
  'crema': 'Cuidado personal',
  'perfume': 'Cuidado personal',
  'maquillaje': 'Cuidado personal',
  // Ropa
  'ropa': 'Ropa',
  'zapatos': 'Ropa',
  'tenis': 'Ropa',
  'camisa': 'Ropa',
  'camiseta': 'Ropa',
  'pantalon': 'Ropa',
  'jean': 'Ropa',
  'vestido': 'Ropa',
  'medias': 'Ropa',
  // Entretenimiento
  'cine': 'Entretenimiento',
  'rumba': 'Entretenimiento',
  'fiesta': 'Entretenimiento',
  'cerveza': 'Entretenimiento',
  'cervezas': 'Entretenimiento',
  'polas': 'Entretenimiento',
  'trago': 'Entretenimiento',
  'aguardiente': 'Entretenimiento',
  'concierto': 'Entretenimiento',
  'partido': 'Entretenimiento',
  'juego': 'Entretenimiento',
  'regalo': 'Entretenimiento',
  // Educación
  'matricula': 'Educación',
  'colegio': 'Educación',
  'universidad': 'Educación',
  'curso': 'Educación',
  'libro': 'Educación',
  'libros': 'Educación',
  'cuaderno': 'Educación',
  'fotocopias': 'Educación',
  'utiles': 'Educación',
  // Mascotas
  'veterinario': 'Mascotas',
  'concentrado': 'Mascotas',
  'gato': 'Mascotas',
  'arena': 'Mascotas',
  // Tecnología
  'celular': 'Tecnología',
  'audifonos': 'Tecnología',
  'cargador': 'Tecnología',
  'computador': 'Tecnología',
  // Viajes
  'hotel': 'Viajes',
  'vuelo': 'Viajes',
  'tiquete': 'Viajes',
  'tiquetes': 'Viajes',
  'paseo': 'Viajes',
};

/// Todos los nombres (y alias) normalizados, con su grupo.
final Map<
  String,
  ({NombreConocido nombre, GrupoNombres grupo, String? categoria})
>
_porNombre = () {
  final mapa =
      <
        String,
        ({NombreConocido nombre, GrupoNombres grupo, String? categoria})
      >{};
  for (final g in gruposNombres) {
    for (final n in g.nombres) {
      final dato = (nombre: n, grupo: g, categoria: n.categoria ?? g.categoria);
      for (final forma in [n.nombre, ...n.alias]) {
        mapa.putIfAbsent(normalizarNombre(forma), () => dato);
      }
    }
  }
  return mapa;
}();

/// Cuántos nombres hay en la lista (sin contar alias).
int get totalNombresConocidos =>
    gruposNombres.fold(0, (t, g) => t + g.nombres.length);

/// Si un grupo tiene sentido para un gasto (fijo o del día a día): todo
/// menos bancos, billeteras, tarjetas, financieras, cooperativas y cajas,
/// que son de deudas.
bool esGrupoDeGasto(GrupoNombres g) =>
    g.categoria != null || g.tipoDeuda == TipoDeuda.tienda;

/// Nombres que empiezan (o tienen una palabra que empieza) como [texto],
/// sin importar tildes ni mayúsculas. Primero los que empiezan igual. Con
/// [grupos] solo se buscan los grupos que cumplan (ver [esGrupoDeGasto]).
List<Sugerencia> sugerirNombres(
  String texto, {
  int limite = 8,
  bool Function(GrupoNombres)? grupos,
}) {
  final buscado = normalizarNombre(texto);
  if (buscado.length < 2) return const [];
  final alInicio = <Sugerencia>[];
  final enMedio = <Sugerencia>[];
  final vistos = <String>{};
  for (final g in gruposNombres) {
    if (grupos != null && !grupos(g)) continue;
    for (final n in g.nombres) {
      if (!vistos.add(n.nombre)) continue;
      final formas = [n.nombre, ...n.alias].map(normalizarNombre);
      if (formas.any((f) => f.startsWith(buscado))) {
        alInicio.add(Sugerencia(n.nombre, g));
      } else if (formas.any((f) => f.contains(' $buscado'))) {
        enMedio.add(Sugerencia(n.nombre, g));
      }
    }
  }
  return [...alInicio, ...enMedio].take(limite).toList();
}

/// Categoría que sugiere la lista para un gasto que nunca se ha anotado
/// ("D1 mercado" → Alimentación, "uber" → Transporte). Mira primero el
/// texto completo, luego pares de palabras ("juan valdez") y luego cada
/// palabra. `null` si no reconoce nada.
String? categoriaPorNombre(String descripcion) {
  final texto = normalizarNombre(descripcion);
  if (texto.isEmpty) return null;
  // Una palabra común gana a una marca que se escribe igual ("metro" es
  // más a menudo el pasaje que el supermercado).
  final completo = palabrasCategoria[texto] ?? _porNombre[texto]?.categoria;
  if (completo != null) return completo;
  final palabras = texto
      .split(RegExp(r"[^a-z0-9ñ&'+!-]+"))
      .where((p) => p.isNotEmpty)
      .toList();
  for (var i = 0; i + 1 < palabras.length; i++) {
    final par = _porNombre['${palabras[i]} ${palabras[i + 1]}']?.categoria;
    if (par != null) return par;
  }
  for (final p in palabras) {
    final c = palabrasCategoria[p] ?? _porNombre[p]?.categoria;
    if (c != null) return c;
  }
  return null;
}

/// El tipo de deuda que corresponde a un nombre conocido ("Nu" → tarjeta),
/// o `null` si no está en la lista.
TipoDeuda? tipoDeudaPorNombre(String nombre) =>
    _porNombre[normalizarNombre(nombre)]?.grupo.tipoDeuda;
