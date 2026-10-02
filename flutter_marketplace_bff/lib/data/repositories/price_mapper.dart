/// O BFF envia reais com casas decimais; o app trabalha em centavos.
/// Arredondar elimina o erro de ponto flutuante (399.9 * 100).
int reaisToCents(num reais) => (reais * 100).round();
