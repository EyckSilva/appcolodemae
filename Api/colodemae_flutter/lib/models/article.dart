import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Categorias da biblioteca de conteúdos sobre amamentação.
enum ArticleCategory { pega, ordenha, amamentacao, sono }

extension ArticleCategoryLabel on ArticleCategory {
  String get label {
    switch (this) {
      case ArticleCategory.pega:
        return 'Pega';
      case ArticleCategory.ordenha:
        return 'Ordenha';
      case ArticleCategory.amamentacao:
        return 'Amamentação';
      case ArticleCategory.sono:
        return 'Sono & Rotina';
    }
  }

  IconData get icon {
    switch (this) {
      case ArticleCategory.pega:
        return LucideIcons.mouth;
      case ArticleCategory.ordenha:
        return LucideIcons.droplets;
      case ArticleCategory.amamentacao:
        return LucideIcons.milk;
      case ArticleCategory.sono:
        return LucideIcons.moon;
    }
  }
}

/// Um passo curto do guia: um ícone, um título e no máximo duas frases,
/// para que a mãe leia com calma, uma tela de cada vez.
class ArticleStep {
  const ArticleStep({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;
}

class Article {
  const Article({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.steps,
  });

  final String id;
  final ArticleCategory category;
  final String title;
  final String description;

  /// Passo a passo exibido no guia (modal) do artigo.
  final List<ArticleStep> steps;
}

const List<Article> articles = [
  Article(
    id: 'p1',
    category: ArticleCategory.pega,
    title: 'Como identificar a pega correta',
    description: 'Os sinais de uma pega eficaz, sem dor.',
    steps: [
      ArticleStep(
        icon: LucideIcons.heartHandshake,
        title: 'Barriga com barriga',
        text: 'Deixe o bebê de frente para você, com a barriga encostada na sua e a cabeça alinhada ao corpo.',
      ),
      ArticleStep(
        icon: LucideIcons.smile,
        title: 'Espere a boca bem aberta',
        text: 'Aproxime o bebê do peito quando ele abrir a boca como num bocejo. O queixo encosta primeiro.',
      ),
      ArticleStep(
        icon: LucideIcons.circleCheck,
        title: 'Boca pega a aréola',
        text: 'Ele deve abocanhar o bico e boa parte da aréola. Os lábios ficam virados para fora, como um beicinho.',
      ),
      ArticleStep(
        icon: LucideIcons.heart,
        title: 'Puxa, mas não dói',
        text: 'Você sente uma tração forte, mas não dor. Se doer a mamada inteira, tire e tente de novo.',
      ),
    ],
  ),
  Article(
    id: 'p2',
    category: ArticleCategory.pega,
    title: 'Sinais de má pega',
    description: 'Quando algo precisa ser ajustado.',
    steps: [
      ArticleStep(
        icon: LucideIcons.triangleAlert,
        title: 'Dor que não passa',
        text: 'Dor durante toda a mamada costuma indicar que o bebê está pegando só o bico.',
      ),
      ArticleStep(
        icon: LucideIcons.ear,
        title: 'Barulhinho de estalo',
        text: 'Estalos ao mamar mostram que ele está perdendo a pega e engolindo ar.',
      ),
      ArticleStep(
        icon: LucideIcons.eye,
        title: 'Observe o rostinho',
        text: 'Bochechas encovadas ou lábios virados para dentro são sinais de alerta.',
      ),
      ArticleStep(
        icon: LucideIcons.stethoscope,
        title: 'Peça ajuda cedo',
        text: 'Mamilo rachado ou machucado? Procure o BLH ou o pediatra. Corrigir cedo evita dor.',
      ),
    ],
  ),
  Article(
    id: 'p3',
    category: ArticleCategory.pega,
    title: 'Posições para amamentar',
    description: 'Encontre a posição mais confortável para vocês.',
    steps: [
      ArticleStep(
        icon: LucideIcons.baby,
        title: 'Tradicional (berço)',
        text: 'A cabeça do bebê fica na dobra do seu braço, barriga com barriga. A mais usada no dia a dia.',
      ),
      ArticleStep(
        icon: LucideIcons.sofa,
        title: 'Invertida',
        text: 'O corpo do bebê fica embaixo do seu braço, apoiado numa almofada. Ótima depois de cesárea.',
      ),
      ArticleStep(
        icon: LucideIcons.bedDouble,
        title: 'Deitada de lado',
        text: 'Vocês duas de lado, frente a frente. Perfeita para as mamadas da madrugada.',
      ),
      ArticleStep(
        icon: LucideIcons.heart,
        title: 'O que importa',
        text: 'Pescoço do bebê sem torcer e você confortável. Use almofadas sempre que precisar.',
      ),
    ],
  ),
  Article(
    id: 'o1',
    category: ArticleCategory.ordenha,
    title: 'Como fazer a ordenha',
    description: 'Ordenha manual, com calma e sem dor.',
    steps: [
      ArticleStep(
        icon: LucideIcons.sprayCan,
        title: 'Mãos limpas',
        text: 'Lave bem as mãos e o frasco. Escolha um cantinho tranquilo.',
      ),
      ArticleStep(
        icon: LucideIcons.hand,
        title: 'Massageie o peito',
        text: 'Faça movimentos circulares suaves. Isso ajuda o leite a descer.',
      ),
      ArticleStep(
        icon: LucideIcons.droplets,
        title: 'Dedos em "C"',
        text: 'Polegar acima da aréola, dedos abaixo. Empurre para trás e aperte, sem deslizar na pele.',
      ),
      ArticleStep(
        icon: LucideIcons.refreshCw,
        title: 'Alterne os lados',
        text: 'Uns 3 a 5 minutos em cada peito, até o fluxo diminuir. Depois troque.',
      ),
    ],
  ),
  Article(
    id: 'o2',
    category: ArticleCategory.ordenha,
    title: 'Higienização dos utensílios',
    description: 'Para manter o leite seguro.',
    steps: [
      ArticleStep(
        icon: LucideIcons.sprayCan,
        title: 'Sempre mãos limpas',
        text: 'Lave as mãos com água e sabão antes de tocar em qualquer utensílio.',
      ),
      ArticleStep(
        icon: LucideIcons.glassWater,
        title: 'Frasco de vidro',
        text: 'Use frasco de vidro com tampa plástica. Evite sacos plásticos comuns.',
      ),
      ArticleStep(
        icon: LucideIcons.flame,
        title: 'Ferva por 15 minutos',
        text: 'Lave com detergente neutro e ferva o frasco e a tampa, totalmente cobertos de água.',
      ),
      ArticleStep(
        icon: LucideIcons.circleCheck,
        title: 'Bombinha também',
        text: 'Peças que tocam o leite devem ser lavadas depois de cada uso.',
      ),
    ],
  ),
  Article(
    id: 'o3',
    category: ArticleCategory.ordenha,
    title: 'Armazenamento do leite',
    description: 'Quanto tempo o leite dura em cada lugar.',
    steps: [
      ArticleStep(
        icon: LucideIcons.calendar,
        title: 'Anote data e hora',
        text: 'Etiquete cada frasco. Assim você usa primeiro o leite mais antigo.',
      ),
      ArticleStep(
        icon: LucideIcons.refrigerator,
        title: 'Geladeira: até 12h',
        text: 'Guarde no fundo da geladeira, nunca na porta.',
      ),
      ArticleStep(
        icon: LucideIcons.snowflake,
        title: 'Freezer: até 15 dias',
        text: 'Deixe um espacinho vazio no frasco, porque o leite expande ao congelar.',
      ),
      ArticleStep(
        icon: LucideIcons.thermometer,
        title: 'Descongele com cuidado',
        text: 'Na geladeira ou em banho-maria, sem ferver. Nunca no micro-ondas e nunca recongele.',
      ),
    ],
  ),
  Article(
    id: 'a1',
    category: ArticleCategory.amamentacao,
    title: 'Livre demanda',
    description: 'Amamentar sempre que o bebê pedir.',
    steps: [
      ArticleStep(
        icon: LucideIcons.clock,
        title: 'Sem relógio',
        text: 'Ofereça o peito sempre que o bebê quiser, sem horário fixo e sem limitar o tempo.',
      ),
      ArticleStep(
        icon: LucideIcons.repeat,
        title: '8 a 12 vezes por dia',
        text: 'É normal o recém-nascido mamar a cada 2 ou 3 horas. Cada bebê tem seu ritmo.',
      ),
      ArticleStep(
        icon: LucideIcons.eye,
        title: 'Sinais de fome',
        text: 'Virar a cabeça procurando o peito e levar a mão à boca vêm antes do choro.',
      ),
      ArticleStep(
        icon: LucideIcons.heart,
        title: 'Confie no seu bebê',
        text: 'Quanto mais ele mama, mais leite você produz.',
      ),
    ],
  ),
  Article(
    id: 'a2',
    category: ArticleCategory.amamentacao,
    title: 'Aleitamento exclusivo',
    description: 'Só leite materno até os 6 meses.',
    steps: [
      ArticleStep(
        icon: LucideIcons.milk,
        title: 'Só o leite do peito',
        text: 'Até os 6 meses, nada de água, chá ou suco. É a recomendação da OMS e do Ministério da Saúde.',
      ),
      ArticleStep(
        icon: LucideIcons.sun,
        title: 'Mesmo no calor',
        text: 'Seu leite já tem toda a água de que o bebê precisa.',
      ),
      ArticleStep(
        icon: LucideIcons.shieldCheck,
        title: 'Proteção sob medida',
        text: 'O leite muda conforme o bebê cresce e leva anticorpos que nenhuma fórmula tem.',
      ),
      ArticleStep(
        icon: LucideIcons.calendar,
        title: 'Depois dos 6 meses',
        text: 'Começa a introdução alimentar, e o peito pode continuar até os 2 anos ou mais.',
      ),
    ],
  ),
  Article(
    id: 'a3',
    category: ArticleCategory.amamentacao,
    title: 'Dúvidas dos primeiros dias',
    description: 'Respostas rápidas para as primeiras semanas.',
    steps: [
      ArticleStep(
        icon: LucideIcons.timer,
        title: 'Quanto tempo em cada peito?',
        text: 'Não há tempo fixo. Espere o bebê soltar sozinho e relaxar as mãozinhas.',
      ),
      ArticleStep(
        icon: LucideIcons.circleAlert,
        title: 'Dói no começo?',
        text: 'Um leve incômodo na pega é comum. Dor a mamada toda não é, e vale corrigir a pega.',
      ),
      ArticleStep(
        icon: LucideIcons.thermometer,
        title: 'Peito empedrado?',
        text: 'Mame com frequência, compressa morna antes, fria depois, e massagem suave.',
      ),
      ArticleStep(
        icon: LucideIcons.baby,
        title: 'Ele mama o suficiente?',
        text: 'Muitas fraldas molhadas e bom ganho de peso são ótimos sinais. Na dúvida, fale com o pediatra.',
      ),
    ],
  ),
  Article(
    id: 's1',
    category: ArticleCategory.sono,
    title: 'Mamadas durante a madrugada',
    description: 'Noites mais tranquilas para vocês duas.',
    steps: [
      ArticleStep(
        icon: LucideIcons.moon,
        title: 'Elas são importantes',
        text: 'Mamar de madrugada ajuda o bebê a ganhar peso e mantém sua produção de leite.',
      ),
      ArticleStep(
        icon: LucideIcons.lamp,
        title: 'Luz baixinha',
        text: 'Use uma luz fraca e indireta, sem telas e sem conversa animada.',
      ),
      ArticleStep(
        icon: LucideIcons.baby,
        title: 'Fralda antes',
        text: 'Troque a fralda antes de mamar para não precisar agitar o bebê depois.',
      ),
      ArticleStep(
        icon: LucideIcons.bedDouble,
        title: 'Descanse junto',
        text: 'Amamentar deitada de lado ajuda você a descansar também.',
      ),
    ],
  ),
  Article(
    id: 's2',
    category: ArticleCategory.sono,
    title: 'Rotina dos primeiros dias',
    description: 'Uma rotina leve, no ritmo do bebê.',
    steps: [
      ArticleStep(
        icon: LucideIcons.clock,
        title: 'Sono picadinho é normal',
        text: 'O recém-nascido dorme até 17h por dia, mas acorda a cada 2 ou 3 horas.',
      ),
      ArticleStep(
        icon: LucideIcons.heart,
        title: 'Siga o ritmo dele',
        text: 'Nas primeiras semanas, observe os sinais de sono e fome em vez de horários rígidos.',
      ),
      ArticleStep(
        icon: LucideIcons.bath,
        title: 'Pequenos rituais',
        text: 'Banho morno e luz baixa à noite ajudam o bebê a diferenciar dia e noite.',
      ),
      ArticleStep(
        icon: LucideIcons.handHeart,
        title: 'Cuide de você',
        text: 'Aceite ajuda e descanse quando puder. O vínculo vale mais que qualquer horário.',
      ),
    ],
  ),
];
