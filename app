import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

class DatabaseHelper(context: Context) : SQLiteOpenHelper(context, "LanchoneteDB", null, 1) {

    override fun onCreate(db: SQLiteDatabase?) {
        // Criar tabelas de produtos, vendas e financeiro
        val createProdutosTable = """
            CREATE TABLE Produtos (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nome TEXT NOT NULL,
                quantidade INTEGER NOT NULL,
                preco REAL NOT NULL
            )
        """.trimIndent()

        val createVendasTable = """
            CREATE TABLE Vendas (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                id_produto INTEGER,
                quantidade INTEGER NOT NULL,
                valor REAL NOT NULL,
                data TEXT NOT NULL,
                FOREIGN KEY (id_produto) REFERENCES Produtos(id)
            )
        """.trimIndent()

        val createFinanceiroTable = """
            CREATE TABLE Financeiro (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                receita REAL NOT NULL,
                despesa REAL NOT NULL,
                data TEXT NOT NULL
            )
        """.trimIndent()

        db?.execSQL(createProdutosTable)
        db?.execSQL(createVendasTable)
        db?.execSQL(createFinanceiroTable)
    }

    override fun onUpgrade(db: SQLiteDatabase?, oldVersion: Int, newVersion: Int) {
        db?.execSQL("DROP TABLE IF EXISTS Produtos")
        db?.execSQL("DROP TABLE IF EXISTS Vendas")
        db?.execSQL("DROP TABLE IF EXISTS Financeiro")
        onCreate(db)
    }
}
data class Produto(val id: Int, val nome: String, val quantidade: Int, val preco: Double)
data class Venda(val id: Int, val idProduto: Int, val quantidade: Int, val valor: Double, val data: String)
fun adicionarProduto(nome: String, quantidade: Int, preco: Double): Long {
    val db = this.writableDatabase
    val contentValues = ContentValues().apply {
        put("nome", nome)
        put("quantidade", quantidade)
        put("preco", preco)
    }
    return db.insert("Produtos", null, contentValues)
}
fun registrarVenda(idProduto: Int, quantidade: Int, valor: Double, data: String): Long {
    val db = this.writableDatabase
    val contentValues = ContentValues().apply {
        put("id_produto", idProduto)
        put("quantidade", quantidade)
        put("valor", valor)
        put("data", data)
    }
    return db.insert("Vendas", null, contentValues)
}
fun atualizarEstoque(idProduto: Int, quantidadeVendida: Int) {
    val db = this.writableDatabase
    val contentValues = ContentValues().apply {
        put("quantidade", "quantidade - $quantidadeVendida")
    }
    db.update("Produtos", contentValues, "id = ?", arrayOf(idProduto.toString()))
}
fun verificarEstoqueBaixo() {
    val db = this.readableDatabase
    val cursor = db.rawQuery("SELECT * FROM Produtos WHERE quantidade < 5", null)
    if (cursor.count > 0) {
        // Enviar Notificação de Estoque Baixo
        while (cursor.moveToNext()) {
            val produtoNome = cursor.getString(cursor.getColumnIndex("nome"))
            enviarAlertaDeEstoqueBaixo(produtoNome)
        }
    }
    cursor.close()
}

fun enviarAlertaDeEstoqueBaixo(produtoNome: String) {
    val builder = NotificationCompat.Builder(this, "estoqueBaixoChannel")
        .setSmallIcon(R.drawable.ic_notification)
        .setContentTitle("Alerta de Estoque Baixo")
        .setContentText("O estoque do produto $produtoNome está baixo.")
        .setPriority(NotificationCompat.PRIORITY_HIGH)

    val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        val channel = NotificationChannel(
            "estoqueBaixoChannel",
            "Alertas de Estoque",
            NotificationManager.IMPORTANCE_HIGH
        )
        notificationManager.createNotificationChannel(channel)
    }

    notificationManager.notify(1, builder.build())
}
fun registrarFinanceiro(receita: Double, despesa: Double, data: String): Long {
    val db = this.writableDatabase
    val contentValues = ContentValues().apply {
        put("receita", receita)
        put("despesa", despesa)
        put("data", data)
    }
    return db.insert("Financeiro", null, contentValues)
}
fun calcularBalançoFinanceiro(): Double {
    val db = this.readableDatabase
    val cursor = db.rawQuery("SELECT SUM(receita), SUM(despesa) FROM Financeiro", null)
    var saldo = 0.0
    if (cursor.moveToFirst()) {
        val totalReceita = cursor.getDouble(0)
        val totalDespesa = cursor.getDouble(1)
        saldo = totalReceita - totalDespesa
    }
    cursor.close()
    return saldo
}
class MainActivity : AppCompatActivity() {

    lateinit var dbHelper: DatabaseHelper
    lateinit var produtoList: ArrayList<Produto>
    lateinit var adapter: ProdutoAdapter

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        dbHelper = DatabaseHelper(this)

        // Exemplo: adicionar um produto
        dbHelper.adicionarProduto("Coca-Cola", 20, 5.0)

        // Exemplo: registrar uma venda
        dbHelper.registrarVenda(1, 2, 10.0, "2024-11-01")

        // Exemplo: atualizar estoque
        dbHelper.atualizarEstoque(1, 2)

        // Verificar estoque baixo
        dbHelper.verificarEstoqueBaixo()

        // Calcular saldo financeiro
        val saldo = dbHelper.calcularBalançoFinanceiro()
        println("Saldo financeiro: $saldo")

        // Exibir produtos em RecyclerView
        // Adaptar o código conforme necessário para a exibição de dados
    }
}
