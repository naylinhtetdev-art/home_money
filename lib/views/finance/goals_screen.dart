import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/saving_goal_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/empty_state.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key, this.addOnOpen = false});

  final bool addOnOpen;

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.addOnOpen)
      WidgetsBinding.instance.addPostFrameCallback((_) => _add());
  }

  @override
  Widget build(BuildContext context) {
    final f = context.watch<FinanceProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Saving goals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Goal'),
      ),
      body: f.goals.isEmpty
          ? const EmptyState(
              title: 'Start saving for something meaningful',
              icon: Icons.savings_outlined,
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: f.goals
                  .map(
                    (g) => Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(g.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            LinearProgressIndicator(value: g.progress),
                            const SizedBox(height: 8),
                            Text(
                              '${formatCurrency(g.savedAmount)} of ${formatCurrency(g.targetAmount)} · ${(g.progress * 100).round()}%',
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => _adjust(g, true),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => _adjust(g, false),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  void _add() {
    final name = TextEditingController();
    final target = TextEditingController();
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('New saving goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Goal name'),
            ),
            TextField(
              controller: target,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Target amount'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final a = double.tryParse(target.text);
              if (name.text.trim().isEmpty || a == null) return;
              final uid = context.read<AuthProvider>().user!.uid;
              await context.read<FinanceProvider>().saveGoal(
                uid,
                SavingGoalModel(
                  id: '',
                  name: name.text.trim(),
                  targetAmount: a,
                  savedAmount: 0,
                  targetDate: DateTime.now().add(const Duration(days: 30)),
                ),
              );
              if (mounted) Navigator.pop(d);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _adjust(SavingGoalModel goal, bool add) {
    final amount = TextEditingController();
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(add ? 'Add to ${goal.name}' : 'Withdraw from ${goal.name}'),
        content: TextField(
          controller: amount,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final a = double.tryParse(amount.text);
              if (a == null || a <= 0) return;
              final uid = context.read<AuthProvider>().user!.uid;
              final updated = SavingGoalModel(
                id: goal.id,
                name: goal.name,
                targetAmount: goal.targetAmount,
                savedAmount: (add
                    ? goal.savedAmount + a
                    : (goal.savedAmount - a).clamp(0, goal.targetAmount)),
                targetDate: goal.targetDate,
                description: goal.description,
              );
              await context.read<FinanceProvider>().saveGoal(uid, updated);
              if (mounted) Navigator.pop(d);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

//class GoalsScreen extends StatefulWidget{const GoalsScreen({super.key,this.addOnOpen=false});final bool addOnOpen;@override State<GoalsScreen>createState()=>_GoalsScreenState();}class _GoalsScreenState extends State<GoalsScreen>{@override void initState(){super.initState();if(widget.addOnOpen)WidgetsBinding.instance.addPostFrameCallback((_)=>_add());}@override Widget build(BuildContext c){final f=c.watch<FinanceProvider>();return Scaffold(appBar:AppBar(title:const Text('Saving goals')),floatingActionButton:FloatingActionButton.extended(onPressed:_add,icon:const Icon(Icons.add),label:const Text('Goal')),body:f.goals.isEmpty?const EmptyState(title:'Start saving for something meaningful',icon:Icons.savings_outlined):ListView(padding:const EdgeInsets.all(16),children:f.goals.map((g)=>Card(child:ListTile(contentPadding:const EdgeInsets.all(16),title:Text(g.name),subtitle:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const SizedBox(height:8),LinearProgressIndicator(value:g.progress),const SizedBox(height:8),Text('${formatCurrency(g.savedAmount)} of ${formatCurrency(g.targetAmount)} · ${(g.progress*100).round()}%')]),trailing:IconButton(icon:const Icon(Icons.add_circle_outline),onPressed:()=>_adjust(g,true)))).toList()));}void _add(){final name=TextEditingController(),target=TextEditingController();showDialog(context:context,builder:(d)=>AlertDialog(title:const Text('New saving goal'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:name,decoration:const InputDecoration(labelText:'Goal name')),TextField(controller:target,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Target amount'))]),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('Cancel')),FilledButton(onPressed:()async{final a=double.tryParse(target.text);if(name.text.trim().isEmpty||a==null)return;await context.read<FinanceProvider>().saveGoal(context.read<AuthProvider>().user!.uid,SavingGoalModel(id:'',name:name.text.trim(),targetAmount:a,savedAmount:0,targetDate:DateTime.now().add(const Duration(days:365))));if(d.mounted)Navigator.pop(d);},child:const Text('Create'))]));}void _adjust(SavingGoalModel g,bool add){final amount=TextEditingController();showDialog(context:context,builder:(d)=>AlertDialog(title:Text('Add money to ${g.name}'),content:TextField(controller:amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Amount')),actions:[FilledButton(onPressed:()async{final a=double.tryParse(amount.text);if(a==null)return;await context.read<FinanceProvider>().saveGoal(context.read<AuthProvider>().user!.uid,SavingGoalModel(id:g.id,name:g.name,targetAmount:g.targetAmount,savedAmount:g.savedAmount+a,targetDate:g.targetDate,description:g.description));if(d.mounted)Navigator.pop(d);},child:const Text('Save'))]));}}
